from math import isqrt
from threading import Thread
from time import perf_counter

from matrix_utils import generate_matrix, matrices_equal
from sequential import multiply_by_rows


def split_range(
    size: int,
    parts: int,
) -> list[tuple[int, int]]:
    """Split range [0, size) into approximately equal parts."""

    return [
        (
            i * size // parts,
            (i + 1) * size // parts,
        )
        for i in range(parts)
    ]


def choose_grid(thread_count: int) -> tuple[int, int]:
    """Choose row and column block counts for the given thread count."""

    row_blocks = isqrt(thread_count)

    while thread_count % row_blocks != 0:
        row_blocks -= 1

    column_blocks = thread_count // row_blocks

    return row_blocks, column_blocks


def multiply_block(
    a: list[list[int]],
    b: list[list[int]],
    c: list[list[int]],
    row_start: int,
    row_end: int,
    column_start: int,
    column_end: int,
) -> None:
    """Calculate one rectangular block of the result matrix."""

    n = len(a)

    for i in range(row_start, row_end):
        for j in range(column_start, column_end):
            value = 0

            for k in range(n):
                value += a[i][k] * b[k][j]

            c[i][j] = value


def multiply_threaded(
    a: list[list[int]],
    b: list[list[int]],
    thread_count: int,
) -> list[list[int]]:
    """Multiply matrices using several worker threads."""

    n = len(a)
    c = [[0] * n for _ in range(n)]

    row_blocks, column_blocks = choose_grid(thread_count)

    if row_blocks > n or column_blocks > n:
        raise ValueError("Too many threads for this matrix size")

    row_ranges = split_range(n, row_blocks)
    column_ranges = split_range(n, column_blocks)

    threads = []

    for row_start, row_end in row_ranges:
        for column_start, column_end in column_ranges:
            thread = Thread(
                target=multiply_block,
                args=(
                    a,
                    b,
                    c,
                    row_start,
                    row_end,
                    column_start,
                    column_end,
                ),
            )

            threads.append(thread)
            thread.start()

    # The main thread waits until every worker finishes.
    for thread in threads:
        thread.join()

    return c


if __name__ == "__main__":
    size = 600
    thread_counts = [1, 2, 4, 8, 16]

    a = generate_matrix(size, seed=1)
    b = generate_matrix(size, seed=2)

    print(f"Matrix size: {size} x {size}")

    start = perf_counter()
    reference = multiply_by_rows(a, b)
    sequential_time = perf_counter() - start

    print(f"Sequential: {sequential_time:.6f} s")
    print()

    for thread_count in thread_counts:
        start = perf_counter()

        result = multiply_threaded(
            a,
            b,
            thread_count,
        )

        elapsed = perf_counter() - start

        print(
            f"Threads: {thread_count:2d} | "
            f"Time: {elapsed:.6f} s | "
            f"Correct: {matrices_equal(reference, result)}"
        )