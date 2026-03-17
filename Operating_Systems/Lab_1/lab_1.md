# Лабораторная работа: ReactOS и NetBSD (часть I и II)

## Общие сведения

**Цель работы:**
- Часть I: развернуть среду сборки ReactOS 0.4.14, пересобрать ядро с выводом фамилии в debug log.
- Часть II: установить NetBSD в VirtualBox, собрать своё ядро нативно (внутри NetBSD) с выводом фамилии в dmesg.

**Исполнитель:** Шалимов

**Основная ОС:** *Windows* / Linux / macOS (с установленным VirtualBox, Git и Python)

---

## ЧАСТЬ I: ReactOS 0.4.14

### 1.1 Подготовка окружения на хосте

#### На Windows:

1. **Скачай RosBE архивом** (не .exe, а .zip):
   - Перейди на https://sourceforge.net/projects/reactos/files/BuildEnvironment/
   - Скачай последнюю версию, например `RosBE-0.x.x-Windows-x86_64.7z`
   - Распакуй в папку, например `C:\RosBE`

2. **Установи (или скачай портативно) VirtualBox:**
   - https://www.virtualbox.org/wiki/Downloads
   - Версия 6.1 или выше подходит отлично

3. **Установи Git для Windows:**
   - https://git-scm.com/download/win
   - Это нужно для клонирования ветки 0.4.14

#### На Linux/macOS:

```bash
# Скачай RosBE архивом (7z формат, распакуй)
# Или установи через пакетный менеджер, если доступно

# Git должен быть уже
git --version

# VirtualBox
sudo apt-get install virtualbox  # Linux
# или скачай с официального сайта
```

### 1.2 Развёртывание RosBE

#### Windows:

```cmd
# Распакуй архив в C:\RosBE
# Открой командную строку и запусти:
cd C:\RosBE\RosBE-Build-Env
RosBE.cmd
```

После запуска `RosBE.cmd` откроется терминал RosBE с автоматически установленными переменными окружения (пути к компилятору, MinGW и т.д.).

#### Linux:

```bash
# Распакуй архив
tar xf RosBE-*.tar.gz -C ~

# Инициализируй переменные окружения
source ~/RosBE/RosBE-Build-Env/RosBE.sh

# Проверь компилятор
gcc --version
```

### 1.3 Клонирование ReactOS 0.4.14

```bash
# Открой терминал RosBE (Windows) или обычный (Linux)
# Перейди в нужную папку, например:
cd C:\workspaces\  # Windows
# или
cd ~/projects/  # Linux

# Клонируй ветку 0.4.14 с --depth 1 для экономии времени
git clone --branch releases/0.4.14 --depth 1 https://github.com/reactos/reactos.git reactos-0.4.14

cd reactos-0.4.14
```

### 1.4 Конфигурация и сборка ReactOS

```bash
# Создай папку сборки
mkdir -p build-amd64
cd build-amd64

# Запусти конфигуратор (это создаст Makefile)
# На Windows (из RosBE терминала):
cmake -G "Ninja Multi-Config" -DENABLE_CCACHE=0 -DCMAKE_TOOLCHAIN_FILE=../toolchain-amd64.cmake ..

# На Linux (если собираешь natively):
cmake -DCMAKE_BUILD_TYPE=RelWithDebInfo -DENABLE_CCACHE=0 ..

# Собери ISO (это займёт 1-3 часа в зависимости от железа)
ninja bootcd
```

После успешной сборки появится файл `bootcd.iso` в папке `build-amd64`.

### 1.5 Создание ВМ ReactOS в VirtualBox

1. В VirtualBox: **Машина → Создать**
2. Параметры:
   - Название: `ReactOS-0.4.14-Lab`
   - Тип: **Other**, версия: **Other/Unknown**
   - RAM: 512 MB — 1 GB
   - Диск: VDI, динамический, 2 GB
3. После создания ВМ:
   - **Параметры → Носители → Оптический диск**
   - Подключи `bootcd.iso` из папки сборки
   - **Параметры → Серийные порты** (если нужен debug log через COM):
     - COM1: **Host Device** или **File**, путь `/tmp/reactos-debug.log`
4. Запусти ВМ: выбери первый вариант (установка ReactOS на весь диск)

После установки и перезагрузки ReactOS готов к работе.

### 1.6 Модификация ядра ReactOS: вставка фамилии

#### На хосте, в исходниках ReactOS:

```bash
# Открой файл инициализации ядра
# Путь: reactos-0.4.14/ntoskrnl/ex/init.c
# или reactos-0.4.14/ntoskrnl/ke/main.c (зависит от версии)

# Найди функцию KiSystemStartup() или ExpInitializeExecutive()
# Добавь в начало (после объявления переменных):
DbgPrint("Kernel initialization: Shalimov\n");
```

**Проще через sed (или вручную в редакторе):**

```bash
cd reactos-0.4.14

# Найди файл с инициализацией
find . -name "*.c" -path "*/ke/*" -o -path "*/ex/*" | grep -i init

# Отредактируй вручную или через sed:
# Например, если файл ntoskrnl/ke/main.c:
sed -i '/KiSystemStartup/,/^{/a\    DbgPrint("Kernel init: Shalimov\\n");' ntoskrnl/ke/main.c

# Проверь результат:
grep -n "Shalimov" ntoskrnl/ke/main.c
```

#### Пересборка ядра (только ядро, без всего остального):

```bash
cd build-amd64

# Удалите старое ядро из кэша (если надо)
rm -rf ntoskrnl

# Пересобери только ядро и bootcd
ninja ntoskrnl
ninja bootcd

# Новый bootcd.iso будет готов
```

### 1.7 Установка модифицированного ядра в ВМ

1. В ВМ ReactOS: выключи или загрузись с LiveCD (можешь использовать старый bootcd.iso)
2. **Или** прямо в ReactOS скопируй новый `ntoskrnl.exe` из смонтированного диска
3. Перезагрузись и проверь debug log

#### Проверка debug log:

```bash
# На хосте, если настроил COM-порт на файл:
cat /tmp/reactos-debug.log | grep -i Shalimov

# Или в самой ВМ ReactOS:
# Сообщение будет выведено при загрузке на консоль
```

---

## ЧАСТЬ II: NetBSD

### 2.1 Подготовка

1. Скачай ISO NetBSD 9.3 или 10.x, архитектуру **amd64**:
   - https://www.netbsd.org/releases/
   - Файл: `NetBSD-9.3-amd64-install.iso` (или похожий)

2. В VirtualBox: **Машина → Создать**
   - Название: `NetBSD-Lab`
   - Тип: **BSD**, версия: **NetBSD (64-bit)**
   - RAM: 1-2 GB
   - Диск: VDI, динамический, 10-20 GB

3. Подключи ISO, запусти ВМ

### 2.2 Установка NetBSD

При установке NetBSD:

1. Выбери **guided install** (автоматическая разметка)
2. Согласись на использование всего диска под NetBSD
3. **В списке наборов отметь обязательно:**
   - `base` ✓
   - `etc` ✓
   - `comp` ✓ (компилятор и инструменты)
   - `man` ✓
   - `syssrc` или `src` ✓ **← это критически важно!** (исходники ядра в `/usr/src/sys`)
4. Установи root-пароль
5. Создай обычного пользователя

После установки и перезагрузки ты получишь рабочую NetBSD с исходниками в `/usr/src`.

### 2.3 Подготовка к сборке ядра

**Внутри ВМ NetBSD:**

```bash
# Залогинься под root
su -

# Проверь наличие исходников
ls -la /usr/src/sys/

# Должны быть подкаталоги: arch, kern, uvm, net и т.д.
```

### 2.4 Создание конфига ядра

```bash
cd /usr/src/sys/arch/amd64/conf

# Скопируй стандартный конфиг
cp GENERIC LABSHAL

# Посмотри на содержимое (обычно там уже всё нужное)
cat LABSHAL
```

Файл `LABSHAL` можно оставить как есть; это просто имя конфигурации для сборки.

### 2.5 Модификация исходника ядра: вставка фамилии

**Важно:** исправь ошибку из плана выше. В NetBSD в ядре используется **`printf()`**, а не `cprintf()`.

```bash
cd /usr/src/sys/kern

# Сделай backup
cp init_main.c init_main.c.bak

# Используй awk для вставки строки после "copyright, version"
awk '
/LAB: Shalimov/ { next }
{ print }
$0 ~ /copyright, version/ {
    print "\tprintf(\"LAB: Shalimov\\n\");"
}
' init_main.c.bak > init_main.tmp && mv init_main.tmp init_main.c

# Проверь результат
grep -n "LAB: Shalimov" init_main.c
grep -n "copyright, version" init_main.c
```

Результат должен показать две строки, одна под другой:
```
NNN: (*pr)("%s%s", copyright, version);
NNN+1: printf("LAB: Shalimov\n");
```

### 2.6 Конфигурация и сборка ядра

**Всё это выполняется внутри ВМ NetBSD, нативно (не кросс-компиляция!).**

```bash
# Создай каталог сборки по конфигу LABSHAL
cd /usr/src/sys/arch/amd64/conf
config LABSHAL

# Перейди в каталог сборки
cd ../compile/LABSHAL

# Собери зависимости
make depend

# Собери ядро (это займёт 5-30 минут)
make

# Готовое ядро появится в текущей папке с именем "netbsd"
ls -lh netbsd
```

### 2.7 Установка нового ядра

```bash
# Находишься ещё в /usr/src/sys/arch/amd64/compile/LABSHAL

# Сохрани старое ядро
cp /netbsd /netbsd.old

# Копируй новое ядро на место
cp netbsd /netbsd

# Синхронизируй
sync
```

### 2.8 Перезагрузка и проверка

```bash
# Перезагрузись
shutdown -r now

# После загрузки проверь dmesg
dmesg | grep -i LAB
dmesg | grep -i Shalimov

# Или посмотри полный лог загрузки
cat /var/run/dmesg.boot | grep -i "LAB\|Shalimov"
```

**Ожидаемый результат:** строка вида
```
LAB: Shalimov
```
должна появиться в выводе `dmesg`.

---

## Обнаруженные особенности и ошибки

### ReactOS 0.4.14

- **RosBE .exe не устанавливается:** используй архивную версию `.7z` или `.zip`, распакуй и запусти `RosBE.cmd` / `RosBE.sh` из папки
- **Компиляция долгая:** первая сборка может занять 2-3 часа; используй `-j4` в ninja для параллелизма
- **Debug log:** если настраиваешь через COM-порт, убедись, что путь файла существует

### NetBSD

- **Обязательно выбери `syssrc`/`src` при установке:** без исходников ядра ничего не соберёшь
- **Только нативная сборка:** не кросс-компилируй из Windows/Linux; собирай ядро внутри самой NetBSD
- **Используй `printf()`, не `cprintf()`:** это дефолтный способ вывода в ядре NetBSD
- **Проверяй через `dmesg`:** kernel `printf()` выводит в системный лог, видно через `dmesg` и в файле `/var/run/dmesg.boot`

---

## Проверочный список

### ReactOS:

- [ ] RosBE развёрнут (архивом или установлен)
- [ ] Git клон ветки `releases/0.4.14` успешен
- [ ] `cmake` конфигурация прошла
- [ ] `ninja bootcd` собрал `bootcd.iso`
- [ ] ВМ ReactOS создана в VirtualBox и установлена
- [ ] Найден и отредактирован файл инициализации ядра (добавлена строка `DbgPrint("...Shalimov...")`)
- [ ] Ядро пересобрано (`ninja ntoskrnl && ninja bootcd`)
- [ ] Новый bootcd установлен в ВМ (или скопирован ntoskrnl)
- [ ] ВМ перезагружена и фамилия видна в debug log

### NetBSD:

- [ ] ISO NetBSD 9.x/10.x (amd64) скачан
- [ ] ВМ NetBSD создана в VirtualBox (тип BSD, NetBSD 64-bit)
- [ ] NetBSD установлена с пакетами `base`, `comp`, `syssrc`
- [ ] Исходники ядра в `/usr/src/sys` на месте
- [ ] Конфиг `LABSHAL` скопирован из `GENERIC`
- [ ] Файл `init_main.c` отредактирован (добавлена строка `printf("LAB: Shalimov\n")`)
- [ ] Ядро сконфигурировано (`config LABSHAL`) и собрано (`make depend && make`)
- [ ] Новое ядро скопировано в `/netbsd`, старое в `/netbsd.old`
- [ ] ВМ перезагружена и фамилия видна в `dmesg`

---

## Команды быстрого запуска

### ReactOS (если всё уже установлено):

```bash
# Windows/RosBE терминал
cd build-amd64
ninja bootcd

# Linux
cd build-amd64
ninja bootcd
```

### NetBSD (если нужна пересборка ядра):

```bash
cd /usr/src/sys/arch/amd64/compile/LABSHAL
make depend && make
cp netbsd /netbsd
sync
reboot
```

---

## Итоговый результат

**По завершении лабораторной работы:**

1. **Часть I (ReactOS):**
   - Рабочая ВМ ReactOS 0.4.14 с пересобранным ядром
   - При загрузке ВМ в debug log (консоль или файл) выводится строка с фамилией `Shalimov`

2. **Часть II (NetBSD):**
   - Рабочая ВМ NetBSD с нативно собранным ядром
   - При загрузке ВМ в `dmesg` и `/var/run/dmesg.boot` видна строка `LAB: Shalimov`


