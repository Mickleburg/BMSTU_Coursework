# Лабораторная работа №1

## Тема

Распараллеливание алгоритма вычисления произведения двух матриц.

## Задание

Реализовать стандартное умножение двух квадратных матриц без использования
библиотечных функций матричного умножения и измерить время его выполнения.

Сравнить вычисление результирующей матрицы при обходе её элементов по строкам
и по столбцам.

Реализовать многопоточную версию алгоритма. Результирующая матрица разбивается
на прямоугольные области, каждая из которых вычисляется отдельным потоком.
Провести измерения для различного количества потоков и сравнить результаты
с последовательной реализацией.

После каждого многопоточного вычисления результат проверяется сравнением
с матрицей, полученной стандартным алгоритмом.

## Реализация

Язык: Python.

Для работы с потоками используется стандартный модуль `threading`.
Для измерения времени используется `time.perf_counter()`.

## Файлы

- `matrix_utils.py` — генерация и сравнение матриц.
- `sequential.py` — последовательное умножение матриц.
- `threaded.py` — многопоточное умножение матриц.

## Тестовая система

- ОС: Windows 11 Enterprise 24H2
- Процессор: Intel Core i5-13500H, 2.60 GHz
- Оперативная память: 16 GB, 5200 MT/s

## Результаты

### 1. **При стандартном умножении** при размере матрицы 600 x 600 имеем такие результаты:

```PowerShell
PS
C:\Users\dshalimov\Projects\BMSTU_Coursework\Parallel_and_Distributed_Systems\lab1> python3 .\sequential.py
Matrix size: 600 x 600
By rows:    15.395648 s
By columns: 43.766513 s
Results are equal: True
PS C:\Users\dshalimov\Projects\BMSTU_Coursework\Parallel_and_Distributed_Systems\lab1> python3 .\sequential.py
Matrix size: 600 x 600
By rows:    30.028146 s
By columns: 45.152374 s
Results are equal: True
PS C:\Users\dshalimov\Projects\BMSTU_Coursework\Parallel_and_Distributed_Systems\lab1> python3 .\sequential.py
Matrix size: 600 x 600
By rows:    15.268841 s
By columns: 13.116184 s
Results are equal: True
PS C:\Users\dshalimov\Projects\BMSTU_Coursework\Parallel_and_Distributed_Systems\lab1> python3 .\sequential.py
Matrix size: 600 x 600
By rows:    15.447225 s
By columns: 12.734711 s
Results are equal: True
PS C:\Users\dshalimov\Projects\BMSTU_Coursework\Parallel_and_Distributed_Systems\lab1> python3 .\sequential.py
Matrix size: 600 x 600
By rows:    20.405486 s
By columns: 17.243000 s
Results are equal: True
```
Среднее время дл умножения:

- по строкам:       19.3090692 s
- по столбцам:      26.4025564 s

- среднее общее:    22.86 s

### 2. **При многопоточном выполнении** для аналогично размера матрицы имеем:

```PowerShell
PS C:\Users\dshalimov\Projects\BMSTU_Coursework\Parallel_and_Distributed_Systems\lab1> python3 .\threaded.py
Matrix size: 600 x 600
Sequential: 15.729302 s

Threads:  1 | Time: 15.691145 s | Correct: True
Threads:  2 | Time: 15.678988 s | Correct: True
Threads:  4 | Time: 17.929055 s | Correct: True
Threads:  8 | Time: 18.988887 s | Correct: True
Threads: 16 | Time: 14.490977 s | Correct: True
PS C:\Users\dshalimov\Projects\BMSTU_Coursework\Parallel_and_Distributed_Systems\lab1> python3 .\threaded.py
Matrix size: 600 x 600
Sequential: 17.473048 s

Threads:  1 | Time: 15.487038 s | Correct: True
Threads:  2 | Time: 17.450068 s | Correct: True
Threads:  4 | Time: 16.129044 s | Correct: True
Threads:  8 | Time: 23.573327 s | Correct: True
Threads: 16 | Time: 20.822545 s | Correct: True
PS C:\Users\dshalimov\Projects\BMSTU_Coursework\Parallel_and_Distributed_Systems\lab1> python3 .\threaded.py
Matrix size: 600 x 600
Sequential: 15.118202 s

Threads:  1 | Time: 15.744977 s | Correct: True
Threads:  2 | Time: 15.798223 s | Correct: True
Threads:  4 | Time: 15.496075 s | Correct: True
Threads:  8 | Time: 14.201645 s | Correct: True
Threads: 16 | Time: 24.676427 s | Correct: True
PS C:\Users\dshalimov\Projects\BMSTU_Coursework\Parallel_and_Distributed_Systems\lab1> python3 .\threaded.py
Matrix size: 600 x 600
Sequential: 19.740405 s

Threads:  1 | Time: 15.685924 s | Correct: True
Threads:  2 | Time: 17.410224 s | Correct: True
Threads:  4 | Time: 19.400910 s | Correct: True
Threads:  8 | Time: 18.608313 s | Correct: True
Threads: 16 | Time: 15.750285 s | Correct: True
PS C:\Users\dshalimov\Projects\BMSTU_Coursework\Parallel_and_Distributed_Systems\lab1> python3 .\threaded.py
Matrix size: 600 x 600
Sequential: 21.803569 s

Threads:  1 | Time: 15.338326 s | Correct: True
Threads:  2 | Time: 17.836082 s | Correct: True
Threads:  4 | Time: 34.285540 s | Correct: True
Threads:  8 | Time: 16.850755 s | Correct: True
Threads: 16 | Time: 15.004022 s | Correct: True
```

Среднее время:

- для стандартного умножения:   17.9729052 s
- для одного потока             15.589482 s
- для двух потоков:             16.834717 s
- для четырёх потоков:          20.6481248 s
- для восьми потоков:           18.4445854 s
- для 16-ти потоков:            18.1488512 s

### 3. **Заключение**

По результатам запусков последовательное умножение по строкам в среднем оказалось
быстрее, чем по столбцам: 19.31 с против 26.40 с.

Многопоточная версия не показала стабильного ускорения: среднее время составило
15.59 с для 1 потока, 16.83 с для 2, 20.65 с для 4, 18.44 с для 8 и 18.15 с
для 16 потоков.

Время выполнения заметно меняется между отдельными запусками, поэтому увеличение
числа потоков в данной реализации не даёт устойчивого прироста производительности.