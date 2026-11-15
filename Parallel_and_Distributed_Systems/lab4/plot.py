"""Draw the results of the independent task1 and task3 Go programs."""
import csv
import json
from pathlib import Path

import matplotlib.pyplot as plt

root = Path(__file__).parent
rows = []
for name in ("task1.csv", "task3.csv"):
    with (root / "results" / name).open() as file:
        rows.extend(csv.DictReader(file))
with (root / "results/fields.json").open() as file:
    fields = json.load(file)

fig, axes = plt.subplots(1, 2, figsize=(9, 4))
for ax, field, title in zip(axes, fields, ("Шаг 0", "Шаг 20")):
    ax.imshow(field, cmap="binary", vmin=0, vmax=1, interpolation="nearest")
    ax.set_title(title)
    ax.set_axis_off()
fig.tight_layout()
fig.savefig(root / "images/lab4_evolution.png", dpi=170)
plt.close(fig)

# Evolution uses mean time per generation; other tasks use total time.
fig, axes = plt.subplots(2, 2, figsize=(10, 7))
names = ("evolution", "prime", "factorial", "fibonacci")
titles = ("Эволюция: время шага", "Решето: N = 1000000",
          "Факториал: N = 20000", "Фибоначчи: N = 200000")
for ax, name, title in zip(axes.flat, names, titles):
    data = [row for row in rows if row["task"] == name]
    ax.bar(["Без потоков", "1", "2", "4", "8"],
           [float(row["mean_step_or_total_s"]) for row in data])
    ax.set(title=title, xlabel="Число работников", ylabel="Время, с")
    ax.grid(axis="y", alpha=0.3)
fig.tight_layout()
fig.savefig(root / "images/lab4_times.png", dpi=170)
plt.close(fig)
