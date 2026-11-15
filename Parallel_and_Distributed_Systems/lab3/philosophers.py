import argparse
import csv
import math
import random
import threading
import time
from pathlib import Path


THINK = "Размышляет"
LEFT = "Берёт левую вилку"
RIGHT = "Берёт правую вилку"
EAT = "Ест"
PUT = "Кладёт вилки"
STATES = [THINK, LEFT, RIGHT, EAT, PUT]


class Table:
    def __init__(self, count, seconds, seed):
        self.count = count
        self.seconds = seconds
        self.seed = seed
        self.forks = [threading.Lock() for _ in range(count)]
        self.stop = threading.Event()
        self.ready = threading.Barrier(count + 1)
        self.start = threading.Event()
        self.journal_lock = threading.Lock()
        self.held = [[] for _ in range(count)]
        self.meals = [0] * count
        self.events = [(0.0, i, THINK, ()) for i in range(count)]

    def record(self, i, state):
        # The journal lock only protects short log writes, not a whole meal.
        with self.journal_lock:
            elapsed = time.perf_counter() - self.started
            if elapsed >= self.seconds or self.stop.is_set():
                return False
            self.events.append((elapsed, i, state, tuple(self.held[i])))
            return True

    def pause(self, rng, low, high):
        # Event.wait lets the time limit interrupt thinking, eating or picking up.
        remaining = self.seconds - (time.perf_counter() - self.started)
        if remaining <= 0:
            return False
        return not self.stop.wait(min(rng.uniform(low, high), remaining))

    def take(self, i, fork, state, rng):
        if not self.record(i, state):
            return False
        # A short timeout allows a thread waiting for a fork to notice shutdown.
        while not self.stop.is_set():
            if time.perf_counter() - self.started >= self.seconds:
                return False
            if self.forks[fork].acquire(timeout=0.01):
                with self.journal_lock:
                    self.held[i].append(fork)
                if not self.record(i, state):
                    return False
                return self.pause(rng, 0.02, 0.05)
        return False

    def release(self, i):
        with self.journal_lock:
            for fork in self.held[i]:
                self.forks[fork].release()
            self.held[i].clear()
            elapsed = time.perf_counter() - self.started
            if elapsed < self.seconds and not self.stop.is_set():
                self.events.append((elapsed, i, PUT, ()))

    def philosopher(self, i):
        rng = random.Random(self.seed + i)
        left, right = i, (i + 1) % self.count
        # Every philosopher uses the same rule: lower-numbered fork first.
        order = sorted([(left, LEFT), (right, RIGHT)])
        self.ready.wait()
        self.start.wait()
        try:
            while not self.stop.is_set():
                if not self.record(i, THINK) or not self.pause(rng, 0.10, 0.25):
                    break
                for fork, state in order:
                    if not self.take(i, fork, state, rng):
                        return
                if not self.record(i, EAT) or not self.pause(rng, 0.10, 0.20):
                    break
                if time.perf_counter() - self.started >= self.seconds:
                    break
                self.meals[i] += 1
                if not self.record(i, PUT) or not self.pause(rng, 0.02, 0.05):
                    break
                self.release(i)
        finally:
            # Release even when the time limit arrives with only one fork held.
            self.release(i)

    def run(self):
        threads = [
            threading.Thread(target=self.philosopher, args=(i,), name=f"Philosopher-{i+1}")
            for i in range(self.count)
        ]
        for thread in threads:
            thread.start()
        self.ready.wait()
        self.started = time.perf_counter()
        self.start.set()
        self.stop.wait(self.seconds)
        self.stop.set()
        for thread in threads:
            thread.join()
        self.wall_time = time.perf_counter() - self.started
        # Close each state interval at the common simulation deadline.
        last = {i: (THINK, ()) for i in range(self.count)}
        for _, i, state, held in self.events:
            last[i] = (state, held)
        for i in range(self.count):
            state, held = last[i]
            self.events.append((self.seconds, i, state, held))

    def save(self, folder):
        folder.mkdir(parents=True, exist_ok=True)
        with (folder / "events.csv").open("w", encoding="utf-8-sig", newline="") as file:
            writer = csv.writer(file)
            writer.writerow(["time_s", "philosopher", "state", "held_forks"])
            for elapsed, i, state, held in self.events:
                writer.writerow([f"{elapsed:.9f}", i + 1, state,
                                 " ".join(str(fork + 1) for fork in held)])
        lines = [
            f"Философов: {self.count}",
            f"Время моделирования: {self.seconds:g} с",
            f"Время с завершением потоков: {self.wall_time:.3f} с",
            f"Seed: {self.seed}",
            "",
            "Завершённых приёмов пищи:",
        ]
        lines += [f"Философ {i+1}: {meals}" for i, meals in enumerate(self.meals)]
        text = "\n".join(lines) + "\n"
        (folder / "summary.txt").write_text(text, encoding="utf-8")
        print(text)

    def plot(self, folder):
        import matplotlib.pyplot as plt
        from matplotlib.patches import Patch

        colors = dict(zip(STATES, ["#b8c6d1", "#e8b65b", "#c592d0", "#6aae78", "#e48373"]))
        fig, ax = plt.subplots(figsize=(13, max(4, self.count * 0.5)))
        for i in range(self.count):
            events = [event for event in self.events if event[1] == i]
            for before, after in zip(events, events[1:]):
                start, _, state, _ = before
                ax.broken_barh([(start, after[0] - start)], (i + 0.65, 0.7),
                              facecolors=colors[state])
        ax.set(xlabel="Время, с", ylabel="Философ", xlim=(0, self.seconds),
               title=f"Обедающие философы: N = {self.count}")
        ax.set_yticks(range(1, self.count + 1))
        ax.invert_yaxis()
        ax.legend(handles=[Patch(color=colors[state], label=state) for state in STATES],
                  loc="upper center", bbox_to_anchor=(0.5, -0.17), ncol=3)
        fig.tight_layout()
        fig.savefig(folder / "timeline.png", dpi=160, bbox_inches="tight")
        plt.close(fig)


def main():
    parser = argparse.ArgumentParser(description="Задача об обедающих философах")
    parser.add_argument("--count", type=int, default=5)
    parser.add_argument("--seconds", type=float, default=10)
    parser.add_argument("--seed", type=int, default=1)
    parser.add_argument("--output", type=Path, default=Path("results"))
    parser.add_argument("--plot", action="store_true", help="Построить диаграмму (matplotlib)")
    args = parser.parse_args()
    if args.count < 2 or not math.isfinite(args.seconds) or args.seconds <= 0:
        parser.error("Нужно не менее двух философов и положительное конечное время.")
    table = Table(args.count, args.seconds, args.seed)
    table.run()
    table.save(args.output)
    if args.plot:
        table.plot(args.output)


if __name__ == "__main__":
    main()
