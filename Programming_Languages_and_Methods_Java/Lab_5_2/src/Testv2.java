import java.util.*;
import java.util.stream.Stream;
import java.util.stream.Collectors;

class Interval {
    int a, b;

    Interval(int a, int b) {
        if (a > b) {
            this.a = b;
            this.b = a;
        } else {
            this.a = a;
            this.b = b;
        }
    }

    public int size() {
        return b - a;
    }

    public boolean includes(double root1, double root2) {
        return a <= root1 && b >= root1 && a <= root2 && b >= root2;
    }

    @Override
    public String toString() {
        return "[" + a + ", " + b + "]";
    }
}

class IntervalTable {
    HashSet<Interval> table;
    double root1, root2;

    IntervalTable(double root1, double root2) {
        this.table = new HashSet<>();
        this.root1 = root1;
        this.root2 = root2;
    }

    void add(Interval interval) {
        table.add(interval);
    }

    void add(int a, int b) {
        table.add(new Interval(a, b));
    }

    public Stream<Interval> intervalStream() {
        return table.stream()
                .filter(interval -> interval.includes(root1, root2));
    }

    public Optional<Interval> maxInterval() {
        return intervalStream()
                .max(Comparator.comparingInt(Interval::size));
    }
}

public class Testv2 {
    public static void main(String[] args) {
        double a = 1;
        double b = -5;
        double c = 6;
        //Корни 2 и 3

        double discriminant = b * b - 4 * a * c;
        double root1 = 0, root2 = 0;
        if (discriminant >= 0) {
            root1 = (-b + Math.sqrt(discriminant)) / (2 * a);
            root2 = (-b - Math.sqrt(discriminant)) / (2 * a);
        } else {
            System.out.println("Квадратное уравнение не имеет действительных корней.");
            return;
        }

        IntervalTable intervalTable = new IntervalTable(root1, root2);

        intervalTable.add(new Interval(1, 4));
        intervalTable.add(new Interval(2, 5));
        intervalTable.add(new Interval(0, 3));
        intervalTable.add(new Interval(1, 6));
        intervalTable.add(new Interval(2, 7));
        intervalTable.add(new Interval(3, 8));
        intervalTable.add(new Interval(4, 10));
        intervalTable.add(new Interval(1, 2));
        intervalTable.add(new Interval(5, 9));
        intervalTable.add(new Interval(0, 1));

        Stream<Interval> stream = intervalTable.intervalStream();

        Map<String, List<Interval>> grouped = stream.collect(Collectors.groupingBy(
                interval -> getRangeLabel(interval.size())
        ));

        System.out.println("Группировка интервалов по размерам:");
        grouped.forEach((range, intervals) -> {
            System.out.println(range + ": " + intervals);
        });

        Optional<Interval> maxInterval = intervalTable.maxInterval();

        if (maxInterval.isPresent()) {
            System.out.println("\nМаксимальный по размеру интервал, включающий корни: " + maxInterval.get());
        } else {
            System.out.println("\nНет интервалов, включающих корни.");
        }
    }

    private static String getRangeLabel(int size) {
        return size >= 9 ? "9+" : size + "-" + (size + 1);
    }
}