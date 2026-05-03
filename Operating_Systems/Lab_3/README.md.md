# Лабораторная работа 3

## Обзор

Задача лабораторной работы: разработать **загружаемый модуль ядра**, который при загрузке выводит в лог **список процессов в системе**.

Лабораторная состоит из двух частей:

- **Часть I: ReactOS**  
  На базе драйвера из ЛР2 реализовать получение списка процессов и вывод их в **debug log**.
- **Часть II: NetBSD**  
  Реализовать то же самое в виде **LKM (Loadable Kernel Module)** и вывести список процессов в **dmesg**.

---

# ЧАСТЬ I: ReactOS

## Что меняется относительно ЛР2

В ЛР2 у тебя уже был минимальный драйвер:

- `DriverEntry`
- `DriverUnload`
- вывод строки в лог через `DPRINT1`
- `.spec`
- `CMakeLists.txt`
- сборка через `configure.cmd` и `ninja`
- загрузка через `sc create` / `sc start`

В ЛР3 сохраняется **та же схема**, но вместо одной строки с фамилией драйвер должен:

1. получить список процессов,
2. пройти по нему,
3. вывести в отладочный лог PID, PPID и имя процесса.

---

## Часть 1: Структура файлов

Создай структуру:

```text
C:\ReactOS\source\reactos\drivers\lab\
├── CMakeLists.txt
└── lab3drv\
    ├── lab3drv.c
    ├── lab3drv.spec
    └── CMakeLists.txt
```

Если папка `lab` уже есть после ЛР2 — просто добавь в неё новую папку `lab3drv`.

---

## Часть 2: Файл `lab3drv.c`

Путь:

```text
C:\ReactOS\source\reactos\drivers\lab\lab3drv\lab3drv.c
```

Содержимое:

```c
#include <ntddk.h>
#define NDEBUG
#include <debug.h>

typedef enum _SYSTEM_INFORMATION_CLASS
{
    SystemBasicInformation = 0,
    SystemProcessInformation = 5
} SYSTEM_INFORMATION_CLASS;

typedef struct _SYSTEM_PROCESS_INFORMATION
{
    ULONG NextEntryOffset;
    ULONG NumberOfThreads;
    LARGE_INTEGER WorkingSetPrivateSize;
    ULONG HardFaultCount;
    ULONG NumberOfThreadsHighWatermark;
    ULONGLONG CycleTime;
    LARGE_INTEGER CreateTime;
    LARGE_INTEGER UserTime;
    LARGE_INTEGER KernelTime;
    UNICODE_STRING ImageName;
    KPRIORITY BasePriority;
    HANDLE UniqueProcessId;
    HANDLE InheritedFromUniqueProcessId;
    ULONG HandleCount;
    ULONG SessionId;
    ULONG_PTR UniqueProcessKey;
    SIZE_T PeakVirtualSize;
    SIZE_T VirtualSize;
    ULONG PageFaultCount;
    SIZE_T PeakWorkingSetSize;
    SIZE_T WorkingSetSize;
    SIZE_T QuotaPeakPagedPoolUsage;
    SIZE_T QuotaPagedPoolUsage;
    SIZE_T QuotaPeakNonPagedPoolUsage;
    SIZE_T QuotaNonPagedPoolUsage;
    SIZE_T PagefileUsage;
    SIZE_T PeakPagefileUsage;
    SIZE_T PrivatePageCount;
    LARGE_INTEGER ReadOperationCount;
    LARGE_INTEGER WriteOperationCount;
    LARGE_INTEGER OtherOperationCount;
    LARGE_INTEGER ReadTransferCount;
    LARGE_INTEGER WriteTransferCount;
    LARGE_INTEGER OtherTransferCount;
} SYSTEM_PROCESS_INFORMATION, *PSYSTEM_PROCESS_INFORMATION;

NTSYSAPI
NTSTATUS
NTAPI
ZwQuerySystemInformation(
    IN SYSTEM_INFORMATION_CLASS SystemInformationClass,
    OUT PVOID SystemInformation,
    IN ULONG SystemInformationLength,
    OUT PULONG ReturnLength OPTIONAL
);

DRIVER_UNLOAD Lab3Unload;

static VOID Lab3PrintProcesses(VOID)
{
    NTSTATUS Status;
    ULONG Size = 0;
    ULONG ReturnLength = 0;
    PVOID Buffer = NULL;
    PSYSTEM_PROCESS_INFORMATION Spi;

    Status = ZwQuerySystemInformation(SystemProcessInformation,
                                      NULL,
                                      0,
                                      &ReturnLength);

    if (ReturnLength == 0)
    {
        DPRINT1("lab3drv: ZwQuerySystemInformation returned zero length, status=0x%08lx\n", Status);
        return;
    }

    Size = ReturnLength + 0x1000;
    Buffer = ExAllocatePoolWithTag(PagedPool, Size, '3baL');
    if (Buffer == NULL)
    {
        DPRINT1("lab3drv: ExAllocatePoolWithTag failed\n");
        return;
    }

    Status = ZwQuerySystemInformation(SystemProcessInformation,
                                      Buffer,
                                      Size,
                                      &ReturnLength);

    if (!NT_SUCCESS(Status))
    {
        DPRINT1("lab3drv: ZwQuerySystemInformation failed, status=0x%08lx\n", Status);
        ExFreePoolWithTag(Buffer, '3baL');
        return;
    }

    DPRINT1("lab3drv: ===== process list begin =====\n");

    Spi = (PSYSTEM_PROCESS_INFORMATION)Buffer;
    for (;;)
    {
        if (Spi->ImageName.Buffer != NULL && Spi->ImageName.Length > 0)
        {
            DPRINT1("lab3drv: pid=%p ppid=%p threads=%lu handles=%lu session=%lu ws=%lu name=%wZ\n",
                    Spi->UniqueProcessId,
                    Spi->InheritedFromUniqueProcessId,
                    Spi->NumberOfThreads,
                    Spi->HandleCount,
                    Spi->SessionId,
                    (ULONG)Spi->WorkingSetSize,
                    &Spi->ImageName);
        }
        else
        {
            DPRINT1("lab3drv: pid=%p ppid=%p threads=%lu handles=%lu session=%lu ws=%lu name=<System>\n",
                    Spi->UniqueProcessId,
                    Spi->InheritedFromUniqueProcessId,
                    Spi->NumberOfThreads,
                    Spi->HandleCount,
                    Spi->SessionId,
                    (ULONG)Spi->WorkingSetSize);
        }

        if (Spi->NextEntryOffset == 0)
            break;

        Spi = (PSYSTEM_PROCESS_INFORMATION)((PUCHAR)Spi + Spi->NextEntryOffset);
    }

    DPRINT1("lab3drv: ===== process list end =====\n");

    ExFreePoolWithTag(Buffer, '3baL');
}

VOID NTAPI Lab3Unload(IN PDRIVER_OBJECT DriverObject)
{
    UNREFERENCED_PARAMETER(DriverObject);
    DPRINT1("lab3drv: unloaded\n");
}

NTSTATUS NTAPI DriverEntry(IN PDRIVER_OBJECT DriverObject,
                           IN PUNICODE_STRING RegistryPath)
{
    UNREFERENCED_PARAMETER(RegistryPath);

    DriverObject->DriverUnload = Lab3Unload;

    DPRINT1("lab3drv: loaded\n");
    Lab3PrintProcesses();

    return STATUS_SUCCESS;
}
```

---

## Часть 3: Файл `lab3drv.spec`

Путь:

```text
C:\ReactOS\source\reactos\drivers\lab\lab3drv\lab3drv.spec
```

Содержимое:

```text
@ stdcall DriverEntry(ptr ptr)
```

---

## Часть 4: Файл `CMakeLists.txt` для `lab3drv`

Путь:

```text
C:\ReactOS\source\reactos\drivers\lab\lab3drv\CMakeLists.txt
```

Содержимое:

```cmake
list(APPEND SOURCE
    lab3drv.c)

add_library(lab3drv MODULE ${SOURCE})
set_module_type(lab3drv kernelmodedriver)
add_importlibs(lab3drv ntoskrnl hal)
add_cd_file(TARGET lab3drv DESTINATION reactos/system32/drivers FOR all)
```

---

## Часть 5: Родительский `CMakeLists.txt`

Путь:

```text
C:\ReactOS\source\reactos\drivers\lab\CMakeLists.txt
```

Если в ЛР2 там был только `lab2drv`, добавь `lab3drv`:

```cmake
add_subdirectory(lab2drv)
add_subdirectory(lab3drv)
```

Если `lab2drv` уже не нужен, можешь оставить только:

```cmake
add_subdirectory(lab3drv)
```

---

## Часть 6: Регистрация в общей системе сборки

Открой:

```text
C:\ReactOS\source\reactos\drivers\CMakeLists.txt
```

Если строка уже была добавлена в ЛР2, **ничего менять не надо**:

```cmake
add_subdirectory(lab)
```

Если её нет — добавь.

---

## Часть 7: Конфигурация и сборка

Все команды выполняй в **RosBE**.

### 7.1 Перегенерация build-дерева

```cmd
cd /d C:\ReactOS\source\reactos
configure.cmd
```

### 7.2 Войти в build-папку

```cmd
cd /d C:\ReactOS\source\reactos\output-MinGW-i386
```

### 7.3 Если `rsym.exe` блокируется Device Guard

На некоторых машинах сборка падает на шаге запуска `rsym.exe`.  
Тогда нужно отключить rossym-постобработку:

```cmd
cmake -DNO_ROSSYM:BOOL=TRUE ..
```

Если всё хорошо, в выводе появится строка:

```text
Generating a dwarf-based build (no rsym)
```

### 7.4 Собрать драйвер

```cmd
ninja lab3drv
```

После успешной сборки должно получиться:

```text
[2/2] Linking C shared module drivers\lab\lab3drv\lab3drv.sys
```

---

## Часть 8: Найти собранный файл

```cmd
dir /s /b lab3drv.sys
```

Обычно он находится по пути:

```text
C:\ReactOS\source\reactos\output-MinGW-i386\drivers\lab\lab3drv\lab3drv.sys
```

---

## Часть 9: Создание ISO и перенос в ReactOS

### 9.1 Подготовка папки

```cmd
mkdir C:\ReactOS\lab3-iso
copy C:\ReactOS\source\reactos\output-MinGW-i386\drivers\lab\lab3drv\lab3drv.sys C:\ReactOS\lab3-iso\
```

### 9.2 Создание ISO через CDBurnerXP

1. Открой **CDBurnerXP**
2. Выбери **Data disc**
3. Добавь **только** файл `lab3drv.sys`
4. Сохрани ISO, например:

```text
C:\ReactOS\lab3drv.iso
```

### 9.3 Подключение ISO к ВМ

В VirtualBox:

1. Выключи ВМ ReactOS
2. **Настройки -> Носители**
3. Добавь второй DVD-привод, если его нет
4. Подключи `C:\ReactOS\lab3drv.iso`
5. Запусти ВМ

### 9.4 Копирование файла внутри ReactOS

Внутри ReactOS:

```cmd
copy D:\lab3drv.sys C:\ReactOS\system32\drivers\lab3drv.sys
```

Если это не `D:`, проверь:

```cmd
dir D:\
dir E:\
```

Проверка:

```cmd
dir C:\ReactOS\system32\drivers\lab3drv.sys
```

---

## Часть 10: Загрузка драйвера

Если драйвер **создаётся впервые**:

```cmd
sc create lab3drv type= kernel binpath= C:\ReactOS\system32\drivers\lab3drv.sys
sc start lab3drv
```

Если сервис уже был создан раньше, повторно делать `sc create` не надо:

```cmd
sc start lab3drv
```

### Важно про `sc.exe`

После `type=` и `binpath=` **обязателен пробел**:

```cmd
sc create lab3drv type= kernel binpath= C:\ReactOS\system32\drivers\lab3drv.sys
```

Именно такой синтаксис нужен для NT-систем.

---

## Часть 11: Просмотр debug log через PuTTY

### 11.1 Настройка COM1 в VirtualBox

В VirtualBox:

- **Настройки -> Последовательные порты**
- **Порт 1 (COM1)**: включить
- **Режим порта**: `Host Pipe`
- **Подключиться к существующему каналу**: выключено
- **Путь**:

```text
\\.\pipe\ros_pipe
```

### 11.2 Настройка PuTTY на Windows

1. Открой **PuTTY**
2. В левом меню выбери **Connection -> Serial**
3. Укажи:
   - **Serial line**: `\\.\pipe\ros_pipe`
   - **Speed**: `115200`
4. Нажми **Open**

### 11.3 Что должно появиться

После `sc start lab3drv` в окне PuTTY должны появиться строки вида:

```text
lab3drv: loaded
lab3drv: ===== process list begin =====
lab3drv: pid=00000004 ppid=00000000 threads=... handles=... session=0 ws=... name=<System>
lab3drv: pid=00000030 ppid=00000004 threads=... handles=... session=0 ws=... name=smss.exe
lab3drv: pid=00000044 ppid=00000030 threads=... handles=... session=0 ws=... name=csrss.exe
...
lab3drv: ===== process list end =====
```

### 11.4 Запись лога в файл

Если хочешь сохранять лог:

1. В PuTTY открой **Session -> Logging**
2. Выбери **All session output**
3. Укажи файл, например:

```text
C:\ReactOS\logs\reactos-lab3.txt
```

Проверка на хосте:

```cmd
type C:\ReactOS\logs\reactos-lab3.txt | findstr lab3drv
```

---

## Часть 12: Выгрузка драйвера

```cmd
sc stop lab3drv
```

Если ReactOS вернёт ошибку `1052`, это допустимо для простого учебного legacy-драйвера.  
Главный критерий ЛР3 — драйвер загружается и выводит список процессов.

---

# ЧАСТЬ II: NetBSD

## Что меняется относительно ЛР2

В ЛР2 у тебя уже был минимальный LKM:

- `MODULE(MODULE_CLASS_MISC, ...)`
- `MODULE_CMD_INIT`
- `MODULE_CMD_FINI`
- отдельный `Makefile`
- сборка через `make`
- загрузка через `modload ./...kmod`
- просмотр вывода через `dmesg`

В ЛР3 схема остаётся прежней.  
Меняется только логика модуля: вместо одной строки с фамилией он должен пройти по списку процессов и вывести PID, PPID и имя процесса.

---

## Часть 1: Подготовка удобного ввода через PuTTY

Чтобы не перепечатывать код руками в консоли NetBSD, удобно подключиться к ВМ из Windows через **PuTTY по SSH**.

### 1.1 Включить SSH в NetBSD

Под `root`:

```sh
echo 'sshd=YES' >> /etc/rc.conf
service sshd start
```

### 1.2 Если используешь root по паролю

Открой `/etc/ssh/sshd_config` и добавь в конец:

```text
PermitRootLogin yes
PasswordAuthentication yes
KbdInteractiveAuthentication yes
```

Проверка конфига и перезапуск:

```sh
sshd -t
service sshd restart
```

### 1.3 Настроить проброс порта в VirtualBox

Если ВМ работает через **NAT**, настрой проброс:

- **Settings -> Network -> Adapter 1 -> NAT**
- **Advanced -> Port Forwarding**

Добавь правило:

- **Name**: `ssh`
- **Protocol**: `TCP`
- **Host Port**: `2222`
- **Guest Port**: `22`

### 1.4 Подключение через PuTTY

На Windows в PuTTY:

- **Host Name**: `127.0.0.1`
- **Port**: `2222`
- **Connection type**: `SSH`

### 1.5 Как копировать и вставлять в PuTTY

#### Вставка из Windows в NetBSD

- **ПКМ** в окне PuTTY  
или
- **Shift + Insert**

#### Копирование из NetBSD в Windows

- просто **выдели текст мышкой**
- после отпускания кнопки он автоматически попадёт в буфер обмена Windows

> Важно: `Ctrl + V` в обычном PuTTY, как правило, не работает.  
> Для вставки используй **ПКМ** или **Shift + Insert**.

---

## Часть 2: Установка `nano`

Если сеть в NetBSD работает, можно установить `nano`.

### 2.1 Проверка архитектуры и версии

```sh
uname -m
uname -r
```

Для стандартной ВМ у тебя обычно будет:

```text
amd64
10.1
```

### 2.2 Настройка репозитория пакетов

```sh
export PKG_PATH="http://cdn.NetBSD.org/pub/pkgsrc/packages/NetBSD/amd64/10.1/All"
```

### 2.3 Установка `nano`

```sh
pkg_add -v nano
```

### 2.4 Проверка

```sh
nano --version
```

Если установка не проходит из-за сети, временно можно использовать встроенный редактор `vi` или создать файлы через `cat <<EOF`.

---

## Часть 3: Проверка исходников ядра

Убедись, что исходники установлены:

```sh
ls /usr/src/sys
ls /usr/src/sys/modules/Makefile.inc
```

Если `/usr/src/sys` или `Makefile.inc` отсутствуют — при установке NetBSD не был выбран набор `syssrc`/`src`.

---

## Часть 4: Проверка securelevel

Для загрузки модулей нужен `kern.securelevel = 0`.

Проверка:

```sh
sysctl kern.securelevel
```

Если значение `>= 1`, добавь в `/etc/rc.conf`:

```sh
echo 'securelevel=0' >> /etc/rc.conf
reboot
```

После перезагрузки снова проверь:

```sh
sysctl kern.securelevel
```

---

## Часть 5: Создание файла `/usr/src/sys/dev/lab3.c`

Если `nano` установлен:

```sh
nano /usr/src/sys/dev/lab3.c
```

Содержимое:

```c
#include <sys/cdefs.h>
#include <sys/param.h>
#include <sys/module.h>
#include <sys/proc.h>
#include <sys/systm.h>
#include <sys/mutex.h>
#include <sys/errno.h>

MODULE(MODULE_CLASS_MISC, lab3, NULL);

static void
lab3_dump_processes(void)
{
    struct proc *p;

    mutex_enter(&proc_lock);

    printf("lab3: ===== process list begin =====\n");

    PROCLIST_FOREACH(p, &allproc) {
        pid_t ppid = -1;

        if (p->p_pptr != NULL)
            ppid = p->p_pptr->p_pid;

        printf("lab3: pid=%d ppid=%d comm=%s\n",
               p->p_pid,
               ppid,
               p->p_comm);
    }

    printf("lab3: ===== process list end =====\n");

    mutex_exit(&proc_lock);
}

static int
lab3_modcmd(modcmd_t cmd, void *arg)
{
    (void)arg;

    switch (cmd) {
    case MODULE_CMD_INIT:
        printf("lab3: loaded\n");
        lab3_dump_processes();
        return 0;

    case MODULE_CMD_FINI:
        printf("lab3: unloaded\n");
        return 0;

    default:
        return ENOTTY;
    }
}
```

### Альтернатива без редактора

Если `nano` ещё нет, можно создать файл так:

```sh
cat > /usr/src/sys/dev/lab3.c << 'EOF'
#include <sys/cdefs.h>
#include <sys/param.h>
#include <sys/module.h>
#include <sys/proc.h>
#include <sys/systm.h>
#include <sys/mutex.h>
#include <sys/errno.h>

MODULE(MODULE_CLASS_MISC, lab3, NULL);

static void
lab3_dump_processes(void)
{
    struct proc *p;

    mutex_enter(&proc_lock);

    printf("lab3: ===== process list begin =====\n");

    PROCLIST_FOREACH(p, &allproc) {
        pid_t ppid = -1;

        if (p->p_pptr != NULL)
            ppid = p->p_pptr->p_pid;

        printf("lab3: pid=%d ppid=%d comm=%s\n",
               p->p_pid,
               ppid,
               p->p_comm);
    }

    printf("lab3: ===== process list end =====\n");

    mutex_exit(&proc_lock);
}

static int
lab3_modcmd(modcmd_t cmd, void *arg)
{
    (void)arg;

    switch (cmd) {
    case MODULE_CMD_INIT:
        printf("lab3: loaded\n");
        lab3_dump_processes();
        return 0;

    case MODULE_CMD_FINI:
        printf("lab3: unloaded\n");
        return 0;

    default:
        return ENOTTY;
    }
}
EOF
```

---

## Часть 6: Создание каталога модуля и Makefile

Если каталога нет, создай его:

```sh
mkdir -p /usr/src/sys/modules/lab3
```

Создай `Makefile`:

```sh
nano /usr/src/sys/modules/lab3/Makefile
```

Содержимое:

```makefile
.include "../Makefile.inc"
KMOD=	lab3
.PATH:	${S}/dev
SRCS=	lab3.c
.include <bsd.kmodule.mk>
```

### Альтернатива без редактора

```sh
cat > /usr/src/sys/modules/lab3/Makefile << 'EOF'
.include "../Makefile.inc"
KMOD=	lab3
.PATH:	${S}/dev
SRCS=	lab3.c
.include <bsd.kmodule.mk>
EOF
```

---

## Часть 7: Сборка модуля

```sh
cd /usr/src/sys/modules/lab3
make
```

После успешной сборки в каталоге появится:

```text
lab3.kmod
```

Проверка:

```sh
ls -la lab3.kmod
```

---

## Часть 8: Загрузка модуля

```sh
modload ./lab3.kmod
```

> Важно: `./` перед именем файла обязателен.  
> Без него `modload` ищет модуль в системных директориях, а не в текущей папке.

---

## Часть 9: Проверка вывода

```sh
dmesg | grep '^lab3:'
```

Ожидаемый результат:

```text
lab3: loaded
lab3: ===== process list begin =====
lab3: pid=0 ppid=-1 comm=swapper
lab3: pid=1 ppid=0 comm=init
lab3: pid=...
...
lab3: ===== process list end =====
```

### Проверка списка загруженных модулей

```sh
modstat
```

---

## Часть 10: Выгрузка модуля

```sh
modunload lab3
```

Проверка:

```sh
dmesg | tail -20
```

Ожидаемый вывод:

```text
lab3: unloaded
```

---

## Возможные ошибки и решения

### ReactOS

| Ошибка | Причина | Решение |
|---|---|---|
| `rsym.exe заблокирована политикой Device Guard` | WDAC / Device Guard блокирует host-tool | Выполни `cmake -DNO_ROSSYM:BOOL=TRUE ..` |
| `ninja: unknown target 'lab3drv'` | `lab3drv` не зарегистрирован в `CMakeLists.txt` | Проверь `add_subdirectory(lab3drv)` |
| `sc start` не запускает драйвер | Файл не скопирован в `system32\drivers` | Проверь путь к `lab3drv.sys` |
| нет вывода в PuTTY | COM1 не настроен или PuTTY подключён не к тому pipe | Проверь `\\.\pipe\ros_pipe` и скорость `115200` |

### NetBSD

| Ошибка | Причина | Решение |
|---|---|---|
| `cd: can't cd to /usr/src/sys/modules/lab3` | Папка не создана | Выполни `mkdir -p /usr/src/sys/modules/lab3` |
| `modload: Operation not permitted` | `kern.securelevel >= 1` | Поставь `securelevel=0` в `/etc/rc.conf` |
| `pkg_add: no pkg found` | не настроен `PKG_PATH` | Экспортируй `PKG_PATH` |
| не вставляется текст в PuTTY | используется `Ctrl+V` | Используй **ПКМ** или **Shift + Insert** |
| `make` не находит `lab3.c` | неверный `Makefile` или отсутствует `.PATH` | Проверь содержимое `Makefile` |
| `Version mismatch` при `modload` | модуль собран не под текущее ядро | Сделай `make clean && make` |

