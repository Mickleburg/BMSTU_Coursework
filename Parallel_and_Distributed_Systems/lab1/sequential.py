from time import perf_counter

from matrix_utils import generate_matrix, matrices_equal


def multiply_by_rows(
    a: list[list[int]],
    b: list[list[int]],
) -> list[list[int]]:
    """Multiply matrices while traversing the result matrix by rows."""

    n = len(a)
    c = [[0] * n for _ in range(n)]

    for i in range(n):
        for j in range(n):
            value = 0

            for k in range(n):
                value += a[i][k] * b[k][j]

            c[i][j] = value

    return c


def multiply_by_columns(
    a: list[list[int]],
    b: list[list[int]],
) -> list[list[int]]:
    """Multiply matrices while traversing the result matrix by columns."""

    n = len(a)
    c = [[0] * n for _ in range(n)]

    for j in range(n):
        for i in range(n):
            value = 0

            for k in range(n):
                value += a[i][k] * b[k][j]

            c[i][j] = value

    return c


if __name__ == "__main__":
    size = 600

    a = generate_matrix(size, seed=1)
    b = generate_matrix(size, seed=2)

    start = perf_counter()
    result_by_rows = multiply_by_rows(a, b)
    rows_time = perf_counter() - start

    start = perf_counter()
    result_by_columns = multiply_by_columns(a, b)
    columns_time = perf_counter() - start

    print(f"Matrix size: {size} x {size}")
    print(f"By rows:    {rows_time:.6f} s")
    print(f"By columns: {columns_time:.6f} s")
    print(
        "Results are equal:",
        matrices_equal(result_by_rows, result_by_columns),
    )