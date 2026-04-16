# Лабораторная работа 2: Часть I — Драйвер ReactOS

## Обзор

Задача: создать минимальный loadable kernel driver (`.sys`) для ReactOS/Windows NT, который при загрузке выводит фамилию студента в debug log через `DPRINT1()`.

Архитектура окружения: **i386** (RosBE автоматически определяет тип как `Detected RosBE for i386`). Сборочная папка — `output-MinGW-i386`.

---

## Часть 1: Правильный запуск RosBE

**Нельзя** просто дважды кликать `RosBE.cmd` — окно моментально закрывается. Нужно запустить его **изнутри уже открытой cmd.exe**, чтобы окружение поднялось в текущей сессии.

1. Нажми `Win + R`, введи `cmd`, нажми Enter.
2. В открывшемся окне выполни:
   ```cmd
   cd /d C:\RosBE\
   RosBE.cmd
   ```
   Если путь к `RosBE.cmd` неизвестен, найди его:
   ```cmd
   dir C:\RosBE /s /b | findstr /i RosBE.cmd
   ```
3. После запуска проверь, что окружение активно:
   ```cmd
   gcc --version
   cmake --version
   ninja --version
   echo %ROS_ARCH%
   ```
   У тебя будет `ROS_ARCH=i386` и `gcc (RosBE-Windows) 8.4.0`.

> **Важно:** все дальнейшие команды сборки выполняются **в этом же окне RosBE**, не в обычном cmd.

---

## Часть 2: Создание файлов драйвера

Создай следующую структуру в дереве исходников ReactOS:

```
C:\ReactOS\source\reactos\drivers\lab\
├── CMakeLists.txt
└── lab2drv\
    ├── lab2drv.c
    ├── lab2drv.spec
    └── CMakeLists.txt
```

### Файл 1: `lab2drv.c`

Путь: `C:\ReactOS\source\reactos\drivers\lab\lab2drv\lab2drv.c`

```c
#include <ntddk.h>
#define NDEBUG
#include <debug.h>

DRIVER_UNLOAD Lab2Unload;

VOID NTAPI Lab2Unload(IN PDRIVER_OBJECT DriverObject)
{
    UNREFERENCED_PARAMETER(DriverObject);
    DPRINT1("lab2drv: Shalimov -- unloaded\n");
}

NTSTATUS NTAPI DriverEntry(IN PDRIVER_OBJECT DriverObject,
                           IN PUNICODE_STRING RegistryPath)
{
    UNREFERENCED_PARAMETER(RegistryPath);
    DriverObject->DriverUnload = Lab2Unload;
    DPRINT1("lab2drv: Shalimov\n");
    return STATUS_SUCCESS;
}
```

**Нюансы:**
- `#define NDEBUG` + `#include <debug.h>` — обязательная пара для использования `DPRINT1`. Без `#define NDEBUG` перед `#include <debug.h>` макрос `DPRINT1` не активируется и вывод не будет работать.
- `DRIVER_UNLOAD Lab2Unload;` — forward-декларация через макрос WDK; требуется до определения функции.
- `NTAPI` — вызывающее соглашение `__stdcall`, стандарт для функций NT kernel-mode.
- `DriverObject->DriverUnload = Lab2Unload;` — без этой строки команда `sc stop` вернёт ошибку `ERROR_INVALID_SERVICE_CONTROL (1052)`. При этом `STOPPABLE` в выводе `sc start` всё равно может не появиться для простых legacy-драйверов, — это нормально.
- `UNREFERENCED_PARAMETER` — подавляет warning компилятора о неиспользуемых параметрах.

### Файл 2: `lab2drv.spec`

Путь: `C:\ReactOS\source\reactos\drivers\lab\lab2drv\lab2drv.spec`

```
@ stdcall DriverEntry(ptr ptr)
```

Spec-файл описывает экспортируемые символы `.sys`-файла. Это обязательный элемент системы сборки ReactOS для генерации корректного kernel-mode DLL.

### Файл 3: `CMakeLists.txt` для самого драйвера

Путь: `C:\ReactOS\source\reactos\drivers\lab\lab2drv\CMakeLists.txt`

```cmake
list(APPEND SOURCE
    lab2drv.c)

add_library(lab2drv MODULE ${SOURCE})
set_module_type(lab2drv kernelmodedriver)
add_importlibs(lab2drv ntoskrnl hal)
add_cd_file(TARGET lab2drv DESTINATION reactos/system32/drivers FOR all)
```

**Нюансы:**
- `add_library(... MODULE ...)` — собирает как разделяемый модуль, то есть `.sys`.
- `set_module_type(lab2drv kernelmodedriver)` — CMake-макрос ReactOS, выставляет правильные флаги линкера для kernel-mode.
- `add_importlibs(lab2drv ntoskrnl hal)` — импорт символов из ядра и HAL (Hardware Abstraction Layer); без этого линковка не пройдёт.
- `add_cd_file(...)` — добавляет `lab2drv.sys` в итоговый ISO-образ ReactOS по пути `reactos/system32/drivers/`.

### Файл 4: `CMakeLists.txt` родительской папки `lab`

Путь: `C:\ReactOS\source\reactos\drivers\lab\CMakeLists.txt`

```cmake
add_subdirectory(lab2drv)
```

---

## Часть 3: Регистрация в системе сборки

Открой файл:

```
C:\ReactOS\source\reactos\drivers\CMakeLists.txt
```

Добавь в него строку (порядок добавления среди других `add_subdirectory` не важен):

```cmake
add_subdirectory(lab)
```

> **Почему**: ReactOS использует иерархическую систему CMake-файлов. Если папка не зарегистрирована через `add_subdirectory`, CMake никогда не увидит твои файлы и цель `ninja lab2drv` просто не появится в build-дереве.

---

## Часть 4: Конфигурация и сборка

Все команды выполняются в **окне RosBE**.

### 4.1 Конфигурация (генерация build-дерева)

```cmd
cd /d C:\ReactOS\source\reactos
configure.cmd
```

`configure.cmd` — это стандартный скрипт ReactOS, который сам определяет тип RosBE-окружения (`i386` или `amd64`) через переменную `%ROS_ARCH%` и запускает `cmake` с правильными параметрами. Он создаёт или обновляет папку `output-MinGW-i386`.

> **Важно:** `configure.cmd` нужно перезапускать каждый раз, когда ты добавляешь новые `CMakeLists.txt` или `add_subdirectory` в существующие файлы. Без этого CMake не знает о новых целях.

После успешного завершения:
```
Configure script complete! Execute appropriate build commands (ex: ninja, make, nmake, etc...)
from output-MinGW-i386
```

### 4.2 Сборка драйвера

```cmd
cd /d C:\ReactOS\source\reactos\output-MinGW-i386
ninja lab2drv
```

Успешный финал:
```
[3/3] Linking C shared module drivers\lab\lab2drv\lab2drv.sys
```

### 4.3 Найти собранный файл

```cmd
dir /s /b lab2drv.sys
```

Файл будет по пути вида:
```
C:\ReactOS\source\reactos\output-MinGW-i386\drivers\lab\lab2drv\lab2drv.sys
```

---

## Часть 5: Создание ISO и перенос в ВМ

### 5.1 Подготовка папки

```cmd
mkdir C:\ReactOS\lab2-iso
copy C:\ReactOS\source\reactos\output-MinGW-i386\drivers\lab\lab2drv\lab2drv.sys C:\ReactOS\lab2-iso\
```

### 5.2 Создание ISO через CDBurnerXP

1. Открой **CDBurnerXP**.
2. Выбери **Data disc** (Data project).
3. Добавь **только один файл** `lab2drv.sys` из `C:\ReactOS\lab2-iso\` прямо в корень проекта (без подпапок), чтобы внутри ReactOS файл был доступен как `D:\lab2drv.sys`.
4. Выбери **File → Save as ISO** (или «Записать в ISO-образ») и сохрани, например, как `C:\ReactOS\lab2drv.iso`.

### 5.3 Подключение ISO к ВМ ReactOS

1. В VirtualBox выключи (или заморозь) ВМ ReactOS.
2. **Настройки ВМ → Носители**.
3. Если второго оптического привода нет, нажми **«+»** (добавить привод) → **DVD Drive**.
4. Для второго привода нажми иконку диска → **Выбрать образ диска** → укажи `C:\ReactOS\lab2drv.iso`.
5. Запусти ВМ.

### 5.4 Копирование файла внутри ВМ ReactOS

В командной строке ReactOS:

```cmd
copy D:\lab2drv.sys C:\ReactOS\system32\drivers\lab2drv.sys
```

Если ISO смонтировался не как `D:`, проверь буквы дисков:
```cmd
dir D:\
dir E:\
```

Убедись, что файл скопировался:
```cmd
dir C:\ReactOS\system32\drivers\lab2drv.sys
```

---

## Часть 6: Загрузка драйвера в ReactOS

В командной строке ReactOS:

```cmd
sc create lab2drv type= kernel binpath= C:\ReactOS\system32\drivers\lab2drv.sys
sc start lab2drv
```

> **Критически важно:** после `type=` и `binpath=` обязателен пробел. Это особенность синтаксиса `sc.exe` на NT-системах — без пробела команда молча не выполняется или работает некорректно.

Ожидаемый успешный вывод `sc start`:
```
SERVICE_NAME: lab2drv
        TYPE               : 1  KERNEL_DRIVER
        STATE              : 4  RUNNING
                                (STOPPABLE,NOT_PAUSABLE,IGNORES_SHUTDOWN)
        WIN32_EXIT_CODE    : 0  (0x0)
        SERVICE_EXIT_CODE  : 0  (0x0)
```

**STATE = 4 RUNNING** означает, что драйвер успешно загружен в ядро и функция `DriverEntry` выполнена.

### Про `sc stop`

Для минимального legacy kernel-драйвера без реализации полноценного PnP-интерфейса `sc stop` часто возвращает:
```
ERROR_INVALID_SERVICE_CONTROL (1052)
```
Это **нормально** для учебного драйвера. Такое поведение означает, что Service Control Manager не может послать корректную команду остановки данному типу драйвера. Загрузка и вывод фамилии при этом работают корректно, что и является целью лабы.

---

## Часть 7: Просмотр debug-лога через PuTTY

### 7.1 Настройка VirtualBox (COM1)

В настройках ВМ ReactOS → **COM-порты → Порт 1**:

- **Включить последовательный порт**: ✓
- **Номер порта**: COM1
- **Режим порта**: Host Pipe (Хост-канал)
- **Подключиться к существующему каналу**: ☐ (не отмечено)
- **Путь/Адрес**: `\\.\pipe\ros_pipe`

### 7.2 Настройка PuTTY

1. Открой PuTTY на **хосте Windows** (не внутри ВМ).
2. В левом меню выбери **Connection → Serial**.
3. Настройки:
   - **Serial line**: `\\.\pipe\ros_pipe`
   - **Speed**: `115200`
4. Нажми **Open**.

> **Нюанс:** окно PuTTY лучше открывать **до** запуска ReactOS или сразу после, пока сессия ещё активна. Если PuTTY открыт уже после загрузки ReactOS — некоторые ранние сообщения будут упущены, но сообщения от `sc start lab2drv` всё равно появятся.

### 7.3 Что должно появиться в PuTTY

Вывод `DPRINT1` уходит в debug channel ядра ReactOS и передаётся через COM1. В окне PuTTY среди системных отладочных сообщений ты увидишь строку:

```
(drivers/lab/lab2drv/lab2drv.c:18) lab2drv: Shalimov
```

Формат немного варьируется, но фамилия будет видна. ReactOS дополнительно выводит имя файла и номер строки из исходника — это стандартное поведение `DPRINT1`.

### 7.4 Запись лога в файл

Чтобы сохранять debug log в файл:

1. В PuTTY левая панель → **Session → Logging**.
2. **Session logging**: `All session output`.
3. **Log file name**: `C:\ReactOS\logs\reactos-debug.txt`.

Проверка на хосте после `sc start lab2drv`:
```cmd
type C:\ReactOS\logs\reactos-debug.txt | findstr Shalimov
```

---

## Итог: что должно быть получено

1. ✅ Файлы `lab2drv.c`, `lab2drv.spec`, `CMakeLists.txt` созданы в `drivers\lab\lab2drv\`
2. ✅ В `drivers\CMakeLists.txt` добавлен `add_subdirectory(lab)`
3. ✅ `configure.cmd` + `ninja lab2drv` — успешная сборка `lab2drv.sys`
4. ✅ `lab2drv.sys` скопирован в `C:\ReactOS\system32\drivers\` через ISO
5. ✅ `sc create lab2drv type= kernel binpath= C:\ReactOS\system32\drivers\lab2drv.sys`
6. ✅ `sc start lab2drv` → STATE: RUNNING
7. ✅ В PuTTY через `\\.\pipe\ros_pipe` виден вывод: `lab2drv: Shalimov`

---

# Лабораторная работа 2: Часть II — Loadable Kernel Module для NetBSD

## Обзор

Задача: создать и загрузить модуль ядра (LKM — Loadable Kernel Module) для NetBSD, который выводит фамилию студента в системный лог при загрузке. Модуль компилируется в отдельный файл `lab2.kmod` и **не** встраивается в ядро.

Все команды выполняются **внутри виртуальной машины NetBSD** под пользователем **root**.

---

## Часть 1: Стать root

При входе под обычным пользователем выполни:

```sh
su -
```

Введи пароль root. Убедись, что ты root:

```sh
whoami
# root
```

> **Важно:** `modload` требует root. Обычный пользователь получит `Permission denied`.

---

## Часть 2: Проверить наличие исходников ядра

Исходники ядра NetBSD нужны для сборки модуля. Они должны быть в `/usr/src/sys`:

```sh
ls /usr/src/sys
```

Если папка пустая или её нет — исходники не были установлены при создании ВМ. В этом случае вернись к установке NetBSD и выбери компонент `syssrc` (исходники ядра). Без него `bsd.kmodule.mk` не найдёт заголовочные файлы, и сборка не пройдёт.

Также проверь наличие самого `Makefile.inc` для модулей:

```sh
ls /usr/src/sys/modules/Makefile.inc
```

Если файл существует — окружение сборки модулей в норме.

---

## Часть 3: Проверить securelevel

NetBSD блокирует загрузку модулей при `kern.securelevel >= 1`. Проверь текущий уровень:

```sh
sysctl kern.securelevel
```

Если значение `>= 1`, загрузка модуля будет заблокирована с ошибкой `Operation not permitted`. Понизить securelevel **нельзя** через sysctl на работающей системе — он может только расти. Единственный способ — перезагрузиться и установить `securelevel=0` через `/etc/rc.conf`:

```sh
echo 'securelevel=0' >> /etc/rc.conf
reboot
```

После перезагрузки снова проверь:

```sh
sysctl kern.securelevel
# kern.securelevel = 0
```

---

## Часть 4: Создать файл исходника драйвера

```sh
nano /usr/src/sys/dev/lab2.c
```

Содержимое файла:

```c
#include <sys/cdefs.h>
#include <sys/module.h>
#include <sys/param.h>

MODULE(MODULE_CLASS_MISC, lab2, NULL);

static int
lab2_modcmd(modcmd_t cmd, void *arg)
{
    switch (cmd) {
    case MODULE_CMD_INIT:
        printf("lab2: Shalimov\n");
        return 0;
    case MODULE_CMD_FINI:
        printf("lab2: unloaded\n");
        return 0;
    default:
        return ENOTTY;
    }
}
```

Сохрани файл: `Ctrl+O`, Enter, `Ctrl+X`.

**Разбор кода:**

- `#include <sys/module.h>` — заголовок для `MODULE()`, `modcmd_t`, `MODULE_CLASS_MISC`, `MODULE_CMD_INIT`, `MODULE_CMD_FINI`.
- `#include <sys/param.h>` — нужен для `ENOTTY` и базовых типов ядра.
- `MODULE(MODULE_CLASS_MISC, lab2, NULL)` — регистрирует модуль. Три аргумента: класс (`MISC` = прочий), имя модуля, зависимость (нет).
  - Этот макрос автоматически связывает имя `lab2` с функцией `lab2_modcmd` — по конвенции имя функции должно быть `<имя_модуля>_modcmd`.
- `MODULE_CMD_INIT` — ветка, вызываемая при `modload`. Здесь выводится фамилия.
- `MODULE_CMD_FINI` — ветка, вызываемая при `modunload`.
- `default: return ENOTTY` — **обязательная** ветка `default`. Если вернуть `0`, некоторые неизвестные команды SCM будут молча игнорированы. `ENOTTY` — стандартный возврат для неподдерживаемых команд модуля в NetBSD.
- `printf` — стандартная функция ядра NetBSD; не `printk` (это Linux). Вывод идёт в системный буфер сообщений ядра, читается через `dmesg`.

---

## Часть 5: Создать Makefile для модуля

Создай директорию для модуля:

```sh
mkdir -p /usr/src/sys/modules/lab2
```

Создай Makefile:

```sh
nano /usr/src/sys/modules/lab2/Makefile
```

Содержимое:

```makefile
.include "../Makefile.inc"
KMOD=	lab2
.PATH:	${S}/dev
SRCS=	lab2.c
.include <bsd.kmodule.mk>
```

Сохрани файл: `Ctrl+O`, Enter, `Ctrl+X`.

**Разбор Makefile:**

- `.include "../Makefile.inc"` — подключает общий файл `/usr/src/sys/modules/Makefile.inc`. В нём задаётся переменная `S`, которая автоматически вычисляется как путь к `/usr/src/sys`. **Без этой строки переменная `${S}` будет пустой и `.PATH` укажет в неверное место.**
- `KMOD= lab2` — имя результирующего модуля. Из этого имени также выводится ожидаемое имя функции `lab2_modcmd`.
- `.PATH: ${S}/dev` — указывает `make`, где искать исходный файл `lab2.c`. `${S}` = `/usr/src/sys`, поэтому полный путь = `/usr/src/sys/dev`. Если убрать `.PATH`, `make` будет искать `lab2.c` прямо в папке Makefile и не найдёт его.
- `SRCS= lab2.c` — список исходных файлов.
- `.include <bsd.kmodule.mk>` — основная логика сборки модуля: правила компиляции, линковки, создания `.kmod`.

---

## Часть 6: Сборка модуля

Перейди в папку с Makefile и запусти сборку:

```sh
cd /usr/src/sys/modules/lab2
make
```

Ожидаемый вывод в конце:

```
cc -O2 ... -c /usr/src/sys/dev/lab2.c
ld -r -o lab2.kmod lab2.o ...
```

Финальный файл — `lab2.kmod` — появится в текущей директории:

```sh
ls -la lab2.kmod
```

> **Нюанс:** если `make` выдаёт `cannot open .../machine/types.h` или `No such file or directory` для системных заголовков — скорее всего, исходники ядра (`syssrc`) не установлены полностью. Также убедись, что версия NetBSD во ВМ совпадает с тем, что в `/usr/src`.

---

## Часть 7: Загрузка модуля

```sh
modload ./lab2.kmod
```

> **`./` перед именем файла обязателен.** Без него `modload` интерпретирует аргумент как имя модуля и ищет его в системных директориях (`/stand/...`), а не в текущей папке. С `./` он воспринимает аргумент как путь к файлу.

Если модуль загружен успешно — команда возвращается без ошибок и без вывода.

---

## Часть 8: Проверка вывода фамилии

```sh
dmesg | tail -20
```

Ищи строку вида:

```
lab2: Shalimov
```

Если строки нет в хвосте — поищи точнее:

```sh
dmesg | grep -i lab2
```

Или так (фамилия):

```sh
dmesg | grep -i Shalimov
```

> **Нюанс:** `printf` в ядре NetBSD выводит в кольцевой буфер сообщений ядра, который читается через `dmesg`. Это не терминальный вывод и не `/var/log/messages`. Не жди, что строка появится прямо в консоли при `modload` — смотри именно `dmesg`.

---

## Часть 9: Проверка состояния модуля

Посмотреть список загруженных модулей:

```sh
modstat
```

В выводе будет строка вроде:

```
NAME             CLASS    SOURCE  REFS
lab2             misc     filesys    0
```

---

## Часть 10: Выгрузка модуля

```sh
modunload lab2
```

Здесь уже указывается **имя модуля** (не путь к файлу). Имя берётся из вывода `modstat` или из `KMOD=` в Makefile — в данном случае `lab2`.

После выгрузки в `dmesg` должна появиться строка:

```
lab2: unloaded
```

Проверь:

```sh
dmesg | tail -5
```

---

## Возможные ошибки и решения

| Ошибка | Причина | Решение |
|--------|---------|---------|
| `Operation not permitted` при `modload` | `kern.securelevel >= 1` | Добавь `securelevel=0` в `/etc/rc.conf`, перезагрузись |
| `modload: No such file or directory` без `./` | `modload` ищет в системных директориях | Используй `modload ./lab2.kmod` |
| `make: cannot open .../machine/types.h` | Не установлены `syssrc` | Установи исходники ядра через `sysinst` или из дистрибутива |
| `undefined reference to ...` при линковке | Не хватает `#include` | Добавь `#include <sys/param.h>` и `#include <sys/cdefs.h>` |
| `Version mismatch` при `modload` | Модуль собран под другую версию ядра | Пересобери модуль: `make clean && make` |
| `lab2_modcmd: no such symbol` | Имя функции не совпадает с `KMOD=` | Функция должна называться строго `<KMOD>_modcmd` |
| `dmesg` не показывает фамилию | Буфер переполнен или grep не то | Используй `dmesg | grep -i Shalimov` |
| `modload: Operation not permitted` без securelevel | Не root | Выполни `su -` и повтори |

---

## Итог: что должно быть получено

1. ✅ Файл `/usr/src/sys/dev/lab2.c` создан с `MODULE()` и `printf("lab2: Shalimov\n")`
2. ✅ Файл `/usr/src/sys/modules/lab2/Makefile` создан корректно
3. ✅ `make` завершился без ошибок, создан `lab2.kmod`
4. ✅ `modload ./lab2.kmod` выполнен без ошибок
5. ✅ `dmesg | grep Shalimov` показывает строку `lab2: Shalimov`
6. ✅ `modstat` показывает модуль `lab2` в состоянии `misc`
7. ✅ `modunload lab2` выполнен, `dmesg` показывает `lab2: unloaded`
