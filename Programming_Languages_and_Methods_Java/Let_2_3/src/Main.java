public class Main {
    public static void main(String[] args) {
        Stack<Universe> universeStack = new Stack<>();

        universeStack.push(new Universe("IU9", 200, 10000));
        universeStack.push(new Universe("IU10", 300, -10000));

        Universe removed = universeStack.pop();
        System.out.println("Удалено: " + removed);

        Universe top = universeStack.peek();
        System.out.println("Верхний элемент: " + top);
    }
}