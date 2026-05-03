# Лабораторная работа 4

## Обзор

Задача лабораторной работы — разработать загружаемый модуль ядра, который работает с виртуальной памятью.

Лабораторная состоит из двух частей:

- **ReactOS** — драйвер на базе минимального драйвера из ЛР2: резерв 10 страниц через `ZwAllocateVirtualMemory(..., MEM_RESERVE, ...)`, коммит первых 5 страниц через `MEM_COMMIT`, вывод физических адресов и PTE, освобождение памяти.
- **NetBSD** — LKM на базе схемы из ЛР2–3: резерв kernel virtual address space, ручное отображение 5 физических страниц, вывод VA / PA / PTE, корректная очистка и выгрузка.

Главная идея ЛР4 — показать разницу между:

- резервированием виртуального адресного пространства;
- выделением / коммитом физических страниц;
- сопоставлением виртуального адреса с физическим;
- чтением записи таблицы страниц — PTE.

---

# ЧАСТЬ I: ReactOS

## Что меняется относительно ЛР2–3

Схема проекта остаётся такой же, как в прошлых лабораторных:

- `DriverEntry`;
- `DriverUnload`;
- вывод через `DPRINT1`;
- `.spec`;
- `CMakeLists.txt`;
- сборка через RosBE, `configure.cmd`, `ninja`;
- перенос `.sys` в ReactOS через ISO;
- загрузка через `sc create` / `sc start`;
- просмотр debug log через PuTTY и `\\.\pipe\ros_pipe`.

Меняется только логика внутри драйвера. Теперь при загрузке драйвер:

1. резервирует 10 страниц;
2. коммитит первые 5 страниц;
3. записывает по одному байту в каждую из 5 страниц, чтобы страницы реально получили физические frame'ы;
4. печатает для каждой страницы виртуальный адрес, физический адрес и PTE;
5. освобождает память.

> Код ниже рассчитан на **ReactOS i386** и build-каталог `output-MinGW-i386`. Для amd64 формула чтения PTE будет другой.

---

## 1. Структура файлов

Создай папку:

```text
C:\ReactOS\source\reactos\drivers\lab\lab4drv\
```

Итоговая структура:

```text
C:\ReactOS\source\reactos\drivers\lab\
├── CMakeLists.txt
├── lab2drv\
├── lab3drv\
└── lab4drv\
    ├── lab4drv.c
    ├── lab4drv.spec
    └── CMakeLists.txt
```

---

## 2. Файл `lab4drv.c`

Путь:

```text
C:\ReactOS\source\reactos\drivers\lab\lab4drv\lab4drv.c
```

Содержимое:

```c
#include <ntddk.h>

#define NDEBUG
#include <debug.h>

/*
 * В некоторых версиях ReactOS-заголовков прототипы этих Zw-функций
 * не видны из ntddk.h. Из-за -Werror сборка падает на implicit declaration,
 * поэтому объявляем их вручную.
 */
NTSYSAPI
NTSTATUS
NTAPI
ZwAllocateVirtualMemory(
    IN HANDLE ProcessHandle,
    IN OUT PVOID *BaseAddress,
    IN ULONG_PTR ZeroBits,
    IN OUT PSIZE_T RegionSize,
    IN ULONG AllocationType,
    IN ULONG Protect
);

NTSYSAPI
NTSTATUS
NTAPI
ZwFreeVirtualMemory(
    IN HANDLE ProcessHandle,
    IN OUT PVOID *BaseAddress,
    IN OUT PSIZE_T RegionSize,
    IN ULONG FreeType
);

#define LAB4_TOTAL_PAGES   10
#define LAB4_COMMIT_PAGES  5

/*
 * ReactOS i386 / Windows x86 recursive PTE mapping.
 *
 * Для 32-битного x86 PTE для виртуального адреса VA лежит по адресу:
 *
 *   0xC0000000 + ((VA >> 12) * 4)
 *
 * Это учебный способ получить raw PTE. Он завязан на x86.
 */
#define LAB4_X86_PTE_BASE 0xC0000000UL

#define LAB4_PTE_FROM_VA(va) \
    ((PULONG)(LAB4_X86_PTE_BASE + ((((ULONG_PTR)(va)) >> 12) * sizeof(ULONG))))

DRIVER_UNLOAD Lab4Unload;

static VOID
Lab4DumpVirtualMemoryInfo(PVOID BaseAddress)
{
    ULONG i;

    DPRINT1("lab4drv: ===== committed pages begin =====\n");

    for (i = 0; i < LAB4_COMMIT_PAGES; ++i)
    {
        PUCHAR Va;
        PHYSICAL_ADDRESS Pa;
        volatile ULONG PteValue;

        Va = (PUCHAR)BaseAddress + i * PAGE_SIZE;

        /*
         * Важно: запись нужна, чтобы demand-zero страница реально получила
         * физическую страницу.
         */
        *Va = (UCHAR)(0xA0 + i);

        Pa = MmGetPhysicalAddress(Va);
        PteValue = *LAB4_PTE_FROM_VA(Va);

        DPRINT1("lab4drv: page=%lu va=%p pa=0x%08lx%08lx pte=0x%08lx value=0x%02x\n",
                i,
                Va,
                (ULONG)Pa.HighPart,
                (ULONG)Pa.LowPart,
                PteValue,
                *Va);
    }

    DPRINT1("lab4drv: ===== committed pages end =====\n");
}

static NTSTATUS
Lab4RunMemoryExperiment(VOID)
{
    NTSTATUS Status;
    PVOID BaseAddress = NULL;
    PVOID CommitAddress = NULL;
    PVOID FreeAddress = NULL;
    SIZE_T ReserveSize;
    SIZE_T CommitSize;
    SIZE_T FreeSize;

    ReserveSize = LAB4_TOTAL_PAGES * PAGE_SIZE;

    DPRINT1("lab4drv: reserving %lu pages, size=%lu bytes\n",
            (ULONG)LAB4_TOTAL_PAGES,
            (ULONG)ReserveSize);

    Status = ZwAllocateVirtualMemory(NtCurrentProcess(),
                                     &BaseAddress,
                                     0,
                                     &ReserveSize,
                                     MEM_RESERVE,
                                     PAGE_READWRITE);

    if (!NT_SUCCESS(Status))
    {
        DPRINT1("lab4drv: MEM_RESERVE failed, status=0x%08lx\n", Status);
        return Status;
    }

    DPRINT1("lab4drv: reserved base=%p size=%lu\n",
            BaseAddress,
            (ULONG)ReserveSize);

    CommitAddress = BaseAddress;
    CommitSize = LAB4_COMMIT_PAGES * PAGE_SIZE;

    DPRINT1("lab4drv: committing first %lu pages, size=%lu bytes\n",
            (ULONG)LAB4_COMMIT_PAGES,
            (ULONG)CommitSize);

    Status = ZwAllocateVirtualMemory(NtCurrentProcess(),
                                     &CommitAddress,
                                     0,
                                     &CommitSize,
                                     MEM_COMMIT,
                                     PAGE_READWRITE);

    if (!NT_SUCCESS(Status))
    {
        DPRINT1("lab4drv: MEM_COMMIT failed, status=0x%08lx\n", Status);

        FreeAddress = BaseAddress;
        FreeSize = 0;
        ZwFreeVirtualMemory(NtCurrentProcess(),
                            &FreeAddress,
                            &FreeSize,
                            MEM_RELEASE);

        return Status;
    }

    DPRINT1("lab4drv: committed base=%p size=%lu\n",
            CommitAddress,
            (ULONG)CommitSize);

    Lab4DumpVirtualMemoryInfo(BaseAddress);

    FreeAddress = BaseAddress;
    FreeSize = 0;

    Status = ZwFreeVirtualMemory(NtCurrentProcess(),
                                 &FreeAddress,
                                 &FreeSize,
                                 MEM_RELEASE);

    if (!NT_SUCCESS(Status))
    {
        DPRINT1("lab4drv: MEM_RELEASE failed, status=0x%08lx\n", Status);
        return Status;
    }

    DPRINT1("lab4drv: memory released successfully\n");

    return STATUS_SUCCESS;
}

VOID NTAPI
Lab4Unload(IN PDRIVER_OBJECT DriverObject)
{
    UNREFERENCED_PARAMETER(DriverObject);

    DPRINT1("lab4drv: unloaded\n");
}

NTSTATUS NTAPI
DriverEntry(IN PDRIVER_OBJECT DriverObject,
            IN PUNICODE_STRING RegistryPath)
{
    NTSTATUS Status;

    UNREFERENCED_PARAMETER(RegistryPath);

    DriverObject->DriverUnload = Lab4Unload;

    DPRINT1("lab4drv: loaded\n");

    Status = Lab4RunMemoryExperiment();

    DPRINT1("lab4drv: experiment finished, status=0x%08lx\n", Status);

    return Status;
}
```

### Нюанс с `ZwAllocateVirtualMemory`

Если при сборке появляется:

```text
implicit declaration of function 'ZwAllocateVirtualMemory'
implicit declaration of function 'ZwFreeVirtualMemory'
```

это не значит, что функций нет. Это значит, что в твоей версии заголовков не видны их прототипы. Поэтому они вручную объявлены в начале файла. Без этого из-за `-Werror` сборка падает.

---

## 3. Файл `lab4drv.spec`

Путь:

```text
C:\ReactOS\source\reactos\drivers\lab\lab4drv\lab4drv.spec
```

Содержимое:

```text
@ stdcall DriverEntry(ptr ptr)
```

---

## 4. `CMakeLists.txt` для `lab4drv`

Путь:

```text
C:\ReactOS\source\reactos\drivers\lab\lab4drv\CMakeLists.txt
```

Содержимое:

```cmake
list(APPEND SOURCE
    lab4drv.c)

add_library(lab4drv MODULE ${SOURCE})
set_module_type(lab4drv kernelmodedriver)
add_importlibs(lab4drv ntoskrnl hal)
add_cd_file(TARGET lab4drv DESTINATION reactos/system32/drivers FOR all)
```

---

## 5. Родительский `CMakeLists.txt`

Путь:

```text
C:\ReactOS\source\reactos\drivers\lab\CMakeLists.txt
```

Если оставляешь прошлые лабы:

```cmake
add_subdirectory(lab2drv)
add_subdirectory(lab3drv)
add_subdirectory(lab4drv)
```

Если собираешь только ЛР4:

```cmake
add_subdirectory(lab4drv)
```

В общем файле:

```text
C:\ReactOS\source\reactos\drivers\CMakeLists.txt
```

должна быть строка:

```cmake
add_subdirectory(lab)
```

Если она уже была добавлена в ЛР2–3, повторно добавлять не нужно.

---

## 6. Сборка ReactOS-драйвера

Все команды выполняются в окне **RosBE**.

Если менялись `CMakeLists.txt`, сначала:

```cmd
cd /d C:\ReactOS\source\reactos
configure.cmd
```

Потом:

```cmd
cd /d C:\ReactOS\source\reactos\output-MinGW-i386
ninja lab4drv
```

Проверка результата:

```cmd
dir /s /b lab4drv.sys
```

Ожидаемый путь:

```text
C:\ReactOS\source\reactos\output-MinGW-i386\drivers\lab\lab4drv\lab4drv.sys
```

Если мешает `rsym.exe` / Device Guard:

```cmd
cd /d C:\ReactOS\source\reactos\output-MinGW-i386
cmake -DNO_ROSSYM:BOOL=TRUE ..
ninja lab4drv
```

---

## 7. Перенос драйвера в ReactOS

На Windows-хосте:

```cmd
mkdir C:\ReactOS\lab4-iso
copy C:\ReactOS\source\reactos\output-MinGW-i386\drivers\lab\lab4drv\lab4drv.sys C:\ReactOS\lab4-iso\
```

Через **CDBurnerXP** создай ISO с одним файлом `lab4drv.sys`, например:

```text
C:\ReactOS\lab4drv.iso
```

В VirtualBox подключи ISO вторым DVD-приводом.

Внутри ReactOS:

```cmd
copy D:\lab4drv.sys C:\ReactOS\system32\drivers\lab4drv.sys
```

Если диск не `D:`, проверь:

```cmd
dir D:\
dir E:\
```

---

## 8. PuTTY для ReactOS debug log

В VirtualBox для ReactOS:

```text
Настройки → Последовательные порты → Порт 1
```

Поставь:

```text
Включить последовательный порт: да
Номер порта: COM1
Режим порта: Host Pipe
Подключиться к существующему каналу: нет
Путь/адрес: \\.\pipe\ros_pipe
```

В PuTTY на Windows:

```text
Connection → Serial
Serial line: \\.\pipe\ros_pipe
Speed: 115200
```

PuTTY лучше открыть до `sc start lab4drv`.

---

## 9. Загрузка драйвера

Если сервис создаётся впервые:

```cmd
sc create lab4drv type= kernel binpath= C:\ReactOS\system32\drivers\lab4drv.sys
sc start lab4drv
```

После `type=` и `binpath=` обязателен пробел.

Если сервис уже создан:

```cmd
sc start lab4drv
```

Если нужно пересоздать сервис:

```cmd
sc delete lab4drv
sc create lab4drv type= kernel binpath= C:\ReactOS\system32\drivers\lab4drv.sys
sc start lab4drv
```

---

## 10. Ожидаемый вывод ReactOS

В PuTTY должны появиться строки примерно такого вида:

```text
lab4drv: loaded
lab4drv: reserving 10 pages, size=40960 bytes
lab4drv: reserved base=00130000 size=40960
lab4drv: committing first 5 pages, size=20480 bytes
lab4drv: committed base=00130000 size=20480
lab4drv: ===== committed pages begin =====
lab4drv: page=0 va=00130000 pa=0x0000000003a45000 pte=0x03a45067 value=0xa0
lab4drv: page=1 va=00131000 pa=0x0000000003a46000 pte=0x03a46067 value=0xa1
lab4drv: page=2 va=00132000 pa=0x0000000003a47000 pte=0x03a47067 value=0xa2
lab4drv: page=3 va=00133000 pa=0x0000000003a48000 pte=0x03a48067 value=0xa3
lab4drv: page=4 va=00134000 pa=0x0000000003a49000 pte=0x03a49067 value=0xa4
lab4drv: ===== committed pages end =====
lab4drv: memory released successfully
lab4drv: experiment finished, status=0x00000000
```

Адреса будут отличаться. Важно, чтобы было 5 строк с `VA / PA / PTE` и строка `memory released successfully`.

---

# ЧАСТЬ II: NetBSD

## Что меняется относительно ЛР2–3

Схема LKM остаётся прежней:

- исходник: `/usr/src/sys/dev/lab4.c`;
- каталог модуля: `/usr/src/sys/modules/lab4`;
- `Makefile`;
- сборка через `make`;
- загрузка через `modload ./lab4.kmod`;
- просмотр через `dmesg`;
- выгрузка через `modunload lab4`.

Логика ЛР4 в NetBSD:

1. `uvm_km_alloc(..., UVM_KMF_VAONLY | UVM_KMF_WAITVA)` резервирует 10 страниц kernel virtual address space без физических страниц.
2. `uvm_pagealloc` выделяет физические страницы для первых 5 страниц.
3. `pmap_kenter_pa` отображает физическую страницу в виртуальный адрес.
4. `pmap_update` синхронизирует pmap.
5. `pmap_extract` проверяет физический адрес.
6. `kvtopte` на amd64/x86 позволяет прочитать PTE для kernel VA.
7. `pmap_kremove`, `uvm_pagefree`, `uvm_km_free` очищают ресурсы.

> Код ориентирован на NetBSD **amd64/x86**. На другой архитектуре raw PTE нужно получать иначе.

---

## 1. Подготовка NetBSD

Стать root:

```sh
su -
whoami
```

Проверить исходники:

```sh
ls /usr/src/sys
ls /usr/src/sys/modules/Makefile.inc
```

Проверить `securelevel`:

```sh
sysctl kern.securelevel
```

Если значение `>= 1`:

```sh
echo 'securelevel=0' >> /etc/rc.conf
reboot
```

После перезагрузки:

```sh
sysctl kern.securelevel
```

---

## 2. PuTTY по SSH и `nano`

Если используешь VirtualBox NAT, удобно подключиться через PuTTY.

В NetBSD:

```sh
echo 'sshd=YES' >> /etc/rc.conf
service sshd start
```

Если нужен root-login по паролю, в `/etc/ssh/sshd_config` добавь:

```text
PermitRootLogin yes
PasswordAuthentication yes
KbdInteractiveAuthentication yes
```

Проверка:

```sh
sshd -t
service sshd restart
```

VirtualBox NAT Port Forwarding:

```text
Host Port: 2222
Guest Port: 22
Protocol: TCP
```

PuTTY:

```text
Host: 127.0.0.1
Port: 2222
Connection type: SSH
```

Вставка в PuTTY: **ПКМ** или **Shift + Insert**.

Установка `nano`, если нужно:

```sh
uname -m
uname -r
export PKG_PATH="http://cdn.NetBSD.org/pub/pkgsrc/packages/NetBSD/amd64/10.1/All"
pkg_add -v nano
```

---

## 3. Файл `/usr/src/sys/dev/lab4.c`

Создай файл:

```sh
nano /usr/src/sys/dev/lab4.c
```

Если внизу `nano` появилась строка:

```text
File to insert [from ./]:
```

нажми `Ctrl + C`. Это отменит режим вставки файла.

Содержимое:

```c
#include <sys/cdefs.h>
#include <sys/param.h>
#include <sys/module.h>
#include <sys/systm.h>
#include <sys/errno.h>
#include <sys/types.h>

#include <uvm/uvm.h>

#include <machine/pmap.h>

#if defined(__x86_64__) || defined(__i386__)
#include <machine/pmap_private.h>
#endif

#define LAB4_TOTAL_PAGES   10
#define LAB4_COMMIT_PAGES  5

MODULE(MODULE_CLASS_MISC, lab4, NULL);

static uintmax_t
lab4_read_pte(vaddr_t va)
{
#if defined(__x86_64__) || defined(__i386__)
    pt_entry_t *ptep;

    ptep = kvtopte(va);
    if (ptep == NULL)
        return 0;

    return (uintmax_t)(*ptep);
#else
    return 0;
#endif
}

static void
lab4_cleanup(vaddr_t base, struct vm_page *pages[], int mapped_pages)
{
    int i;

    if (base != 0 && mapped_pages > 0) {
        pmap_kremove(base, mapped_pages * PAGE_SIZE);
        pmap_update(pmap_kernel());
    }

    for (i = 0; i < mapped_pages; ++i) {
        if (pages[i] != NULL) {
            uvm_pagefree(pages[i]);
            pages[i] = NULL;
        }
    }

    if (base != 0) {
        uvm_km_free(kernel_map,
                    base,
                    LAB4_TOTAL_PAGES * PAGE_SIZE,
                    UVM_KMF_VAONLY);
    }
}

static int
lab4_run_memory_experiment(void)
{
    vaddr_t base;
    struct vm_page *pages[LAB4_COMMIT_PAGES];
    int i;
    int mapped_pages;

    for (i = 0; i < LAB4_COMMIT_PAGES; ++i)
        pages[i] = NULL;

    mapped_pages = 0;

    printf("lab4: reserving %d pages, size=%lu bytes\n",
           LAB4_TOTAL_PAGES,
           (unsigned long)(LAB4_TOTAL_PAGES * PAGE_SIZE));

    base = uvm_km_alloc(kernel_map,
                        LAB4_TOTAL_PAGES * PAGE_SIZE,
                        PAGE_SIZE,
                        UVM_KMF_VAONLY | UVM_KMF_WAITVA);

    if (base == 0) {
        printf("lab4: uvm_km_alloc failed\n");
        return ENOMEM;
    }

    printf("lab4: reserved va=%p size=%lu\n",
           (void *)base,
           (unsigned long)(LAB4_TOTAL_PAGES * PAGE_SIZE));

    for (i = 0; i < LAB4_COMMIT_PAGES; ++i) {
        struct vm_page *pg;
        paddr_t pa;
        vaddr_t va;

        va = base + i * PAGE_SIZE;

        pg = uvm_pagealloc(NULL, 0, NULL, UVM_PGA_ZERO);
        if (pg == NULL) {
            printf("lab4: uvm_pagealloc failed at page %d\n", i);
            lab4_cleanup(base, pages, mapped_pages);
            return ENOMEM;
        }

        pages[i] = pg;
        pa = VM_PAGE_TO_PHYS(pg);

        pmap_kenter_pa(va,
                       pa,
                       VM_PROT_READ | VM_PROT_WRITE,
                       0);

        mapped_pages++;

        printf("lab4: committed page=%d va=%p pa=0x%jx\n",
               i,
               (void *)va,
               (uintmax_t)pa);
    }

    pmap_update(pmap_kernel());

    printf("lab4: ===== committed pages begin =====\n");

    for (i = 0; i < LAB4_COMMIT_PAGES; ++i) {
        vaddr_t va;
        paddr_t pa;
        uintmax_t pte;

        va = base + i * PAGE_SIZE;

        *((volatile unsigned char *)va) = (unsigned char)(0xB0 + i);

        if (!pmap_extract(pmap_kernel(), va, &pa)) {
            printf("lab4: page=%d va=%p pa=<no mapping> pte=<unknown>\n",
                   i,
                   (void *)va);
            continue;
        }

        pte = lab4_read_pte(va);

        printf("lab4: page=%d va=%p pa=0x%jx pte=0x%jx value=0x%02x\n",
               i,
               (void *)va,
               (uintmax_t)pa,
               pte,
               *((volatile unsigned char *)va));
    }

    printf("lab4: ===== committed pages end =====\n");

    lab4_cleanup(base, pages, mapped_pages);

    printf("lab4: memory released successfully\n");

    return 0;
}

static int
lab4_modcmd(modcmd_t cmd, void *arg)
{
    int error;

    (void)arg;

    switch (cmd) {
    case MODULE_CMD_INIT:
        printf("lab4: loaded\n");

        error = lab4_run_memory_experiment();
        if (error != 0) {
            printf("lab4: experiment failed, error=%d\n", error);
            return error;
        }

        printf("lab4: experiment finished successfully\n");
        return 0;

    case MODULE_CMD_FINI:
        printf("lab4: unloaded\n");
        return 0;

    default:
        return ENOTTY;
    }
}
```

Сохранение в `nano`:

```text
Ctrl + O
Enter
Ctrl + X
```

---

## 4. Makefile для NetBSD-модуля

Создай каталог:

```sh
mkdir -p /usr/src/sys/modules/lab4
```

Создай файл:

```sh
nano /usr/src/sys/modules/lab4/Makefile
```

Содержимое:

```makefile
.include "../Makefile.inc"

KMOD=  lab4
.PATH: ${S}/dev
SRCS=   lab4.c

.include <bsd.kmodule.mk>
```

Пояснение:

- `KMOD= lab4` задаёт имя модуля;
- функция должна называться `lab4_modcmd`;
- `.PATH: ${S}/dev` говорит `make`, что `lab4.c` лежит в `/usr/src/sys/dev`;
- `<bsd.kmodule.mk>` подключает правила сборки `.kmod`.

---

## 5. Сборка, загрузка и проверка NetBSD-модуля

Сборка:

```sh
cd /usr/src/sys/modules/lab4
make
```

Проверка файла:

```sh
ls -la lab4.kmod
```

Загрузка:

```sh
modload ./lab4.kmod
```

`./` обязателен. Без него `modload` ищет модуль в системных каталогах.

Проверка вывода:

```sh
dmesg | grep '^lab4:'
```

Ожидаемый вывод:

```text
lab4: loaded
lab4: reserving 10 pages, size=40960 bytes
lab4: reserved va=0xffff... size=40960
lab4: committed page=0 va=0xffff... pa=0x...
lab4: committed page=1 va=0xffff... pa=0x...
lab4: committed page=2 va=0xffff... pa=0x...
lab4: committed page=3 va=0xffff... pa=0x...
lab4: committed page=4 va=0xffff... pa=0x...
lab4: ===== committed pages begin =====
lab4: page=0 va=0xffff... pa=0x... pte=0x... value=0xb0
lab4: page=1 va=0xffff... pa=0x... pte=0x... value=0xb1
lab4: page=2 va=0xffff... pa=0x... pte=0x... value=0xb2
lab4: page=3 va=0xffff... pa=0x... pte=0x... value=0xb3
lab4: page=4 va=0xffff... pa=0x... pte=0x... value=0xb4
lab4: ===== committed pages end =====
lab4: memory released successfully
lab4: experiment finished successfully
```

Проверка состояния:

```sh
modstat | grep lab4
```

Выгрузка:

```sh
modunload lab4
```

Проверка:

```sh
dmesg | tail -20
```

Ожидаемая строка:

```text
lab4: unloaded
```

---

# Возможные ошибки и решения

## ReactOS

| Ошибка | Причина | Решение |
|---|---|---|
| `implicit declaration of function 'ZwAllocateVirtualMemory'` | В заголовках не виден прототип | Добавить ручные объявления `ZwAllocateVirtualMemory` и `ZwFreeVirtualMemory` |
| `ninja: unknown target 'lab4drv'` | Драйвер не добавлен в CMake | Проверить `add_subdirectory(lab4drv)` и `add_subdirectory(lab)` |
| `rsym.exe` заблокирован | Device Guard / WDAC | Выполнить `cmake -DNO_ROSSYM:BOOL=TRUE ..` |
| `sc create` не работает | Нет пробела после `type=` или `binpath=` | Использовать правильный синтаксис `sc create lab4drv type= kernel binpath= ...` |
| Нет вывода в PuTTY | Неверный COM/pipe | Проверить `\\.\pipe\ros_pipe` и `115200` |
| PTE выглядит странно | Не i386 | Код чтения PTE рассчитан на ReactOS i386 |
| `sc stop` не выгружает драйвер | Особенность legacy driver | Для лабы допустимо; можно перезагрузить ReactOS |

## NetBSD

| Ошибка | Причина | Решение |
|---|---|---|
| `modload: Operation not permitted` | Не root или `securelevel >= 1` | `su -`; поставить `securelevel=0`, reboot |
| `modload: No such file or directory` | Забыт `./` | Использовать `modload ./lab4.kmod` |
| Нет `/usr/src/sys` | Не установлен `syssrc` | Установить исходники ядра |
| `Version mismatch` | Модуль собран не под текущее ядро | `make clean && make` |
| `File to insert [from ./]:` в nano | Случайный режим вставки файла | Нажать `Ctrl + C` |
| Не вставляется текст в PuTTY | Используется `Ctrl + V` | Использовать ПКМ или `Shift + Insert` |
| Ошибка около `pmap_private.h` / `kvtopte` | Отличие версии или архитектуры | Проверить, что ВМ amd64/x86; для другой архитектуры нужен другой способ чтения PTE |
