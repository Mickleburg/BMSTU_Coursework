# Лабораторная работа: ReactOS и NetBSD
## Полная итоговая инструкция (Windows)

**Основная ОС:** Windows  
**Дата:** Март 2026

---

## ЧАСТЬ I: ReactOS 0.4.14 на Windows

### Этап 1: Подготовка окружения

#### 1.1 Установка необходимого ПО

1. **VirtualBox** (версия 6.1+)
   - Скачай с https://www.virtualbox.org/wiki/Downloads
   - Установи с дефолтными настройками

2. **Git для Windows**
   - Скачай с https://git-scm.com/download/win
   - Установи с опцией "Use Git from the Windows Command Prompt"

3. **RosBE (ReactOS Build Environment) — архивная версия**
   - Перейди на https://sourceforge.net/projects/reactos/files/BuildEnvironment/
   - Скачай **архивную версию** (`.7z` или `.zip`), НЕ `.exe` инсталлер
   - Распакуй архив, например, в папку `C:\RosBE`

#### 1.2 Проверка RosBE

Открой командную строку (cmd.exe) и выполни:

```cmd
cd C:\RosBE\RosBE-Build-Env
RosBE.cmd
```

Откроется терминал RosBE со всеми установленными переменными окружения. Проверь:

```cmd
gcc --version
ninja --version
cmake --version
```

Если всё работает — RosBE готов.

---

### Этап 2: Клонирование исходников ReactOS 0.4.14

В терминале RosBE создай рабочую папку и клонируй код:

```cmd
cd C:\workspaces
git clone --branch releases/0.4.14 --depth 1 https://github.com/reactos/reactos.git reactos-0.4.14
cd reactos-0.4.14
```

**Важно:** используй `--depth 1` — это экономит трафик и время, так как клонируешь только последний коммит ветки.

---

### Этап 3: Конфигурация и сборка ReactOS

**В терминале RosBE, в папке `C:\workspaces\reactos-0.4.14`:**

```cmd
mkdir build-amd64
cd build-amd64

cmake -G "Ninja Multi-Config" -DENABLE_CCACHE=0 -DCMAKE_TOOLCHAIN_FILE=../toolchain-amd64.cmake ..

ninja bootcd
```

**Что происходит:**
- `cmake` создаёт конфигурацию сборки (Ninja files)
- `ninja bootcd` собирает установочный ISO-образ

**Время:** первая сборка заняла у меня минут 30 (а так зависит от CPU и диска).

**Результат:** после успешной сборки появится файл `bootcd.iso` в папке `C:\workspaces\reactos-0.4.14\build-amd64\`.

---

### Этап 4: Создание ВМ ReactOS в VirtualBox

1. Открой VirtualBox
2. **Машина → Создать**
   - Название: `ReactOS-0.4.14-Lab`
   - Тип: `Other`
   - Версия: `Other/Unknown`
   - RAM: `1024 MB`
   - Диск: `VDI`, динамический, `2 GB`
3. Нажми **Создать**

#### 4.1 Настройка носителя (ISO)

В параметрах ВМ:
- **Носители → Оптический диск**
- Нажми на иконку диска
- **Выбрать образ диска** → выбери `C:\workspaces\reactos-0.4.14\build-amd64\bootcd.iso`

#### 4.2 Настройка последовательного порта (для debug log)

В параметрах ВМ:
- **Последовательные порты → COM1**
- Режим: **Host Device**
- ИМЯ ПОРТА: если у тебя есть реальный COM-порт (редко) — выбери его; иначе оставь пусто или выбери **File** и укажи путь типа `C:\temp\reactos-debug.log`

**Примечание:** debug log через COM удобен для анализа, но не критичен для этой лабы.

#### 4.3 Запуск и установка

1. Запусти ВМ
2. При появлении меню загрузки выбери **Live CD** → **Live CD (Debug mode)** или первый вариант для установки
3. Следуй инструкциям установщика:
   - Выбери опцию установить ReactOS на весь диск
   - Заверши установку

После перезагрузки ВМ будет готова к работе.

---

### Этап 5: Модификация ядра ReactOS — вставка фамилии

На хосте (Windows) в исходниках ReactOS:

```cmd
cd C:\workspaces\reactos-0.4.14
```

Найди файл ядра. Обычно это `ntoskrnl/ex/init.c` или `ntoskrnl/ke/main.c`:

```cmd
dir /s /b | findstr "init.c" | findstr "ntoskrnl"
```

Открой этот файл в любом текстовом редакторе (например, Notepad++, VS Code):

```
C:\workspaces\reactos-0.4.14\ntoskrnl\ke\main.c
или
C:\workspaces\reactos-0.4.14\ntoskrnl\ex\init.c
```

Найди функцию инициализации ядра (часто это `KiSystemStartup()` или `ExpInitializeExecutive()`).

**Добавь строку:**

```c
DbgPrint("Kernel initialization: Shalimov\n");
```

сразу после открывающей скобки функции или в самом начале функции (после объявления переменных).

**Пример:**

```c
void KiSystemStartup(void)
{
    // ... другой код ...
    DbgPrint("Kernel initialization: Shalimov\n");
    // ... остальной код ...
}
```

Сохрани файл.

---

### Этап 6: Пересборка ядра

В терминале RosBE:

```cmd
cd C:\workspaces\reactos-0.4.14\build-amd64

ninja ntoskrnl
ninja bootcd
```

Это пересобирает только ядро и создаёт новый `bootcd.iso` с модифицированным ядром.

**Время:** 10–30 минут (намного быстрее, чем полная сборка).

---

### Этап 7: Установка модифицированного ядра в ВМ

#### Способ 1: Переустановка с новым ISO (если ISO не подмонтирован)

1. В VirtualBox: выключи ВМ (если работает)
2. Параметры ВМ → Носители → выбери новый `bootcd.iso` из `build-amd64`
3. Запусти ВМ и переустанови ReactOS

#### Способ 2: Замена ntoskrnl.exe внутри работающей ВМ (рекомендуемый способ — как ты делал)

1. **На хосте:** создай папку с новым ядром:
   ```cmd
   mkdir C:\temp\ReactOS-kernel
   copy C:\workspaces\reactos-0.4.14\build-amd64\ntoskrnl\ntoskrnl.exe C:\temp\ReactOS-kernel\
   ```

2. **Создай ISO из этой папки с помощью CDBurnerXP:**
   - Открой CDBurnerXP
   - **Create a data project → Create a new data CD/DVD**
   - **Add files** → добавь файл `ntoskrnl.exe` из `C:\temp\ReactOS-kernel\`
   - **Write to disc** или **Save as ISO** → сохрани как `kernel.iso`

3. **В VirtualBox:**
   - Параметры ВМ ReactOS → Носители
   - Подключи второй оптический привод: **Добавить привод** → **DVD Drive**
   - К этому приводу подмонтируй `kernel.iso`

4. **Внутри ВМ ReactOS:**
   - Откройся в проводник
   - Перейди на CD диск (второй optical drive) — там будет `ntoskrnl.exe`
   - Скопируй его в системную папку `C:\ReactOS\System32\` (перезапи существующий файл)
   - **Перезагрузись** (`shutdown /r /t 0`)

---

### Этап 8: Проверка вывода debug log

#### Способ 1: На консоли ВМ

При загрузке ВМ на консоли будут видны сообщения ядра (если включен debug mode).

#### Способ 2: Через PuTTY

Если в ВМ установлен и работает Serial Port (COM):

1. **На хосте:** открой PuTTY
2. **Соединение → Serial**
   - Serial line: выбери COM-порт, к которому подключена ВМ (обычно `COM1`)
   - Speed: `115200`
3. Нажми **Open**
4. Перезагрузи ВМ
5. В окне PuTTY появятся сообщения инициализации ядра

**Строка, которую ты должен увидеть:**
```
Kernel initialization: Shalimov
```

#### Способ 3: Захват лога в файл

Если в параметрах ВМ настроил COM1 на режим **File**, логи будут писаться в файл `C:\temp\reactos-debug.log`:

```cmd
type C:\temp\reactos-debug.log | findstr Shalimov
```

---

## ЧАСТЬ II: NetBSD (нативная сборка ядра внутри ВМ)

### Этап 1: Подготовка ISO и создание ВМ

1. **Скачай ISO NetBSD 9.3 или 10.x (amd64):**
   - Перейди на https://www.netbsd.org/releases/
   - Скачай файл вида `NetBSD-9.3-amd64-install.iso` или похожий

2. **Создай ВМ в VirtualBox:**
   - **Машина → Создать**
   - Название: `NetBSD-Lab`
   - Тип: `BSD`
   - Версия: `NetBSD (64-bit)`
   - RAM: `2048 MB` (для удобства сборки)
   - Диск: `VDI`, динамический, `20 GB`

3. **Подключи ISO:**
   - Параметры ВМ → Носители → Оптический диск
   - Выбери загруженный ISO

---

### Этап 2: Установка NetBSD

Запусти ВМ и выполни установку:

1. Выбери **Guided Installation** (автоматическая разметка)
2. Согласись на использование всего диска под NetBSD
3. **КРИТИЧЕСКИ ВАЖНО — В СПИСКЕ НАБОРОВ ОТМЕТЬ:**
   - `base` ✓
   - `etc` ✓
   - `comp` ✓ (компилятор и инструменты разработки)
   - `man` ✓ (документация)
   - `syssrc` или `src` ✓ **← ОБЯЗАТЕЛЬНО!** (исходники ядра `/usr/src/sys`)

4. Установи пароль root и создай обычного пользователя
5. Заверши установку и перезагрузись

После перезагрузки проверь наличие исходников:

```bash
ls -la /usr/src/sys/
```

Должны быть папки: `arch`, `kern`, `uvm`, `net` и т.д.

---

### Этап 3: Подготовка к сборке ядра

**Внутри ВМ NetBSD, залогинься под root:**

```bash
su -
```

Проверь наличие компилятора:

```bash
cc --version
make --version
```

---

### Этап 4: Создание конфигурационного файла ядра

```bash
cd /usr/src/sys/arch/amd64/conf

# Скопируй стандартный конфиг GENERIC в свой файл LABSHAL
cp GENERIC LABSHAL

# Проверь содержимое
cat LABSHAL
```

Файл `LABSHAL` — это конфигурация ядра. Его содержимое можно не менять; он уже содержит всё необходимое.

---

### Этап 5: Модификация исходника ядра — вставка фамилии

#### 5.1 Редактирование файла init_main.c

```bash
cd /usr/src/sys/kern

# Сделай backup
cp init_main.c init_main.c.bak
```

**Открой файл в редакторе:**

```bash
vi init_main.c
```

или используй другой редактор (nano, ee и т.д.).

**Найди в файле строку с `copyright, version`:**

```c
(*pr)("%s%s", copyright, version);
```

**Сразу под этой строкой добавь новую строку:**

```c
printf("LAB: Shalimov\n");
```

**Результат должен выглядеть так:**

```c
(*pr)("%s%s", copyright, version);
printf("LAB: Shalimov\n");
```

Сохрани файл (в `vi`: `Esc`, затем `:wq` и Enter).

#### 5.2 Автоматическая вставка (альтернативный способ)

Если не хочешь редактировать вручную, используй `awk`:

```bash
cd /usr/src/sys/kern

awk '
/LAB: Shalimov/ { next }
{ print }
$0 ~ /copyright, version/ {
    print "\tprintf(\"LAB: Shalimov\\n\");"
}
' init_main.c.bak > init_main.tmp && mv init_main.tmp init_main.c
```

**Проверь результат:**

```bash
grep -n "LAB: Shalimov" init_main.c
grep -n "copyright, version" init_main.c
```

Обе строки должны быть рядом (фамилия сразу под версией).

---

### Этап 6: Конфигурация ядра

```bash
cd /usr/src/sys/arch/amd64/conf

# Генерируем каталог сборки по конфигу LABSHAL
config LABSHAL
```

Эта команда создаст каталог `/usr/src/sys/arch/amd64/compile/LABSHAL` с файлами для сборки.

---

### Этап 7: Сборка ядра (нативная, внутри NetBSD)

```bash
# Перейди в каталог сборки
cd /usr/src/sys/arch/amd64/compile/LABSHAL

# Собери зависимости
make depend

# Собери ядро
make
```

**Что происходит:**
- `make depend` — вычисляет зависимости между файлами
- `make` — компилирует ядро

**Время:** 10–30 минут (зависит от мощности ВМ).

**Результат:** после успешной сборки в текущей папке появится файл `netbsd` (это новое ядро):

```bash
ls -lh netbsd
```

---

### Этап 8: Установка нового ядра

```bash
# Проверь, что находишься в /usr/src/sys/arch/amd64/compile/LABSHAL
pwd

# Сохрани старое ядро (на случай проблем)
cp /netbsd /netbsd.old

# Копируй новое ядро на место старого
cp netbsd /netbsd

# Синхронизируй диск
sync
```

---

### Этап 9: Перезагрузка и проверка

```bash
# Перезагрузись
shutdown -r now
```

После загрузки залогинься и проверь вывод:

```bash
dmesg | grep -i LAB
dmesg | grep -i Shalimov
```

**или**

```bash
cat /var/run/dmesg.boot | grep -i "LAB\|Shalimov"
```

**Ожидаемый результат:**

```
LAB: Shalimov
```

Эта строка должна появиться в выводе `dmesg`, указывая, что новое ядро с твоей фамилией успешно загружено.

---

## Итоговые результаты

### После завершения ЧАСТИ I (ReactOS):

✅ ВМ ReactOS 0.4.14 установлена в VirtualBox  
✅ Ядро пересобрано с добавлением фамилии `Shalimov`  
✅ Новое ядро установлено в ВМ (через CDBurnerXP ISO + замена ntoskrnl.exe)  
✅ При загрузке ВМ в debug log (консоль или PuTTY) видна строка:
```
Kernel initialization: Shalimov
```

### После завершения ЧАСТИ II (NetBSD):

✅ ВМ NetBSD установлена в VirtualBox с исходниками ядра  
✅ Ядро скомпилировано нативно (внутри самой NetBSD) с добавлением фамилии  
✅ Новое ядро установлено (скопировано на место `/netbsd`)  
✅ При загрузке ВМ в `dmesg` видна строка:
```
LAB: Shalimov
```

---

## Полезные команды для быстрой пересборки

### ReactOS (если нужно пересобрать ядро):

```cmd
cd C:\workspaces\reactos-0.4.14\build-amd64
ninja ntoskrnl
ninja bootcd
```

### NetBSD (если нужно пересобрать ядро):

```bash
cd /usr/src/sys/arch/amd64/compile/LABSHAL
make clean
make depend
make
cp netbsd /netbsd
sync
reboot
```

---

## Особенности выполнения (по опыту работы)

1. **RosBE не устанавливается .exe:** используй архивную версию, распакуй архив
2. **Debug log через PuTTY:** для подключения через COM используй скорость 115200 baud
3. **Установка ядра в ReactOS:** способ через CDBurnerXP + копирование `ntoskrnl.exe` — самый надёжный
4. **NetBSD компилируется нативно:** собирай ядро внутри самой NetBSD (не кросс-компиляция)
5. **Проверка NetBSD:** используй `dmesg`, а не консоль — там будут более полные логи
6. **Исходники NetBSD критичны:** обязательно выбери `syssrc`/`src` при установке, иначе ничего не соберёшь

---

**Удачи!**
