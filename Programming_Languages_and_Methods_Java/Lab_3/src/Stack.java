public class Stack<T> {
    private Object[] elements;
    private int top;
    private static final int CAP = 16;

    public Stack() {
        elements = new Object[CAP];
        top = -1;
    }

    public void push(T el) {
        if (top == elements.length - 1) {
            Object[] newArr = new Object[elements.length * 2];

            System.arraycopy(elements, 0, newArr, 0, elements.length);
            elements = newArr;
        }
        elements[++top] = el;
    }

    public T pop() {
        if (top == -1) {
            return null;
        }
        T el = (T) elements[top];
        elements[top--] = null;
        return el;
    }

    public T peek() {
        if (top == -1) {
            return null;
        }
        return (T) elements[top];
    }
}