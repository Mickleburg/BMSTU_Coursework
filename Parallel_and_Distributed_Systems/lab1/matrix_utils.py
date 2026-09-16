from random import Random


def generate_matrix(
    size: int,
    low: int = -10,
    high: int = 10,
    seed: int | None = None,
) -> list[list[int]]:
    """Generate a square matrix filled with random integers."""

    random = Random(seed)

    return [
        [random.randint(low, high) for _ in range(size)]
        for _ in range(size)
    ]


def matrices_equal(
    first: list[list[int]],
    second: list[list[int]],
) -> bool:
    """Check that two matrices are equal."""

    return first == second