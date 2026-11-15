import csv
from pathlib import Path

import matplotlib.pyplot as plt


# Read the measured times; each implementation has its own T(1).
folder = Path(__file__).parent / "results"
with (folder / "times.csv").open(encoding="utf-8-sig", newline="") as file:
    rows = list(csv.DictReader(file))
if len({(row["n"], row["eps"]) for row in rows}) != 1:
    raise ValueError("В таблице смешаны разные N или epsilon.")

fig, axes = plt.subplots(1, 3, figsize=(14, 4))
for name in ("MPI", "OpenMP"):
    data = sorted(
        (row for row in rows if row["implementation"] == name),
        key=lambda row: int(row["workers"]),
    )
    workers = [int(row["workers"]) for row in data]
    if workers != [1, 2, 4, 8, 16]:
        raise ValueError("Нужны замеры для 1, 2, 4, 8 и 16: выполните benchmark.ps1.")
    times = [float(row["seconds"]) for row in data]
    speedup = [times[0] / time for time in times]
    efficiency = [value / count for value, count in zip(speedup, workers)]
    for ax, values in zip(axes, (times, speedup, efficiency)):
        ax.plot(workers, values, "o-", label=name)

# All three plots use the same worker counts.
for ax, title, ylabel in zip(
    axes,
    ("Время", "Ускорение", "Эффективность"),
    ("T(p), с", "T(1) / T(p)", "T(1) / (p · T(p))"),
):
    ax.set(title=title, xlabel="Число процессов / потоков", ylabel=ylabel)
    ax.set_xticks([1, 2, 4, 8, 16])
    ax.grid(True, alpha=0.3)
    ax.legend()

fig.suptitle(f"Метод простой итерации, N = {rows[0]['n']}, ε = {rows[0]['eps']}")
fig.tight_layout()
fig.savefig(folder / "graphs.png", dpi=180)
plt.close(fig)
