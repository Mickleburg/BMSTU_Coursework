import java.util.Arrays;

interface Sorter {
    void sort(int[] array);
}

public class Main {
    public static void main(String[] args) {

        Sorter bubbleSorter = new Sorter() {
            @Override
            public void sort(int[] array) {
                int n = array.length;
                for (int i = 0; i < n - 1; i++) {
                    boolean swapped = false;
                    for (int j = 0; j < n - i - 1; j++) {
                        if (array[j] > array[j + 1]) {

                            int temp = array[j];
                            array[j] = array[j + 1];
                            array[j + 1] = temp;
                            swapped = true;
                        }
                    }

                    if (!swapped) break;
                }
            }
        };

        int[] arr = {64, 34, 25, 12, 22, 11, 90};
        System.out.println("До сортировки: " + Arrays.toString(arr));

        bubbleSorter.sort(arr);

        System.out.println("После сортировки: " + Arrays.toString(arr));
    }
}