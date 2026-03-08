import java.util.*;
import java.util.stream.*;
import java.util.stream.Collectors;

class StringSequence {
    private List<String> strings = new ArrayList<>();

    public void add(String s) {
        strings.add(s);
    }

    public Stream<String> streamContainingNeighbors() {
        if (strings.size() < 3) return Stream.empty();
        return IntStream.range(1, strings.size() - 1)
                .filter(i -> {
                    String current = strings.get(i);
                    String prev = strings.get(i - 1);
                    String next = strings.get(i + 1);
                    return current.contains(prev) && current.contains(next);
                })
                .mapToObj(strings::get);
    }

    public Optional<Integer> findMinN() {
        if (strings.size() < 3) return Optional.of(-1);

        OptionalInt maxViolation = IntStream.range(1, strings.size() - 1)
                .map(i -> {
                    String current = strings.get(i);
                    String prev = strings.get(i - 1);
                    String next = strings.get(i + 1);
                    return (current.contains(prev) || current.contains(next))
                            ? current.length()
                            : Integer.MIN_VALUE;
                })
                .filter(len -> len != Integer.MIN_VALUE)
                .max();

        return maxViolation.isPresent()
                ? Optional.of(maxViolation.getAsInt())
                : Optional.of(-1);
    }
}

public class Testv1 {
    public static void main(String[] args) {
        StringSequence sequence = new StringSequence();
        sequence.add("a");
        sequence.add("aab");
        sequence.add("aaabbb");
        sequence.add("ab");
        sequence.add("abc");

        Map<Integer, List<String>> groupedByLength = sequence.streamContainingNeighbors()
                .collect(Collectors.groupingBy(String::length));

        System.out.println("Группировка по длине:");
        groupedByLength.forEach((len, list) ->
                System.out.println(len + ": " + list));

        Optional<Integer> minN = sequence.findMinN();
        minN.ifPresent(n ->
                System.out.println("Минимальное n: " + n));
    }
}