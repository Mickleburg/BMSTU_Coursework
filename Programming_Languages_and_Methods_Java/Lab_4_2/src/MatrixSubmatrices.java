import java.util.Iterator;
import java.util.NoSuchElementException;
import java.util.ArrayList;
import java.util.List;

public class MatrixSubmatrices implements Iterable<MatrixSubmatrices.Matrix> {
    private final int[][] data;

    public MatrixSubmatrices(int[][] data) {
        this.data = data;
    }

    @Override
    public Iterator<Matrix> iterator() {
        return new ExcludeElementIterator();
    }

    public class Matrix {
        private final List<List<Integer>> values;

        public Matrix(List<List<Integer>> values) {
            this.values = values;
        }

        @Override
        public String toString() {
            StringBuilder sb = new StringBuilder();
            for (List<Integer> row : values) {
                for (Integer val : row) {
                    sb.append(val).append(" ");
                }
                sb.append("\n");
            }
            return sb.toString();
        }
    }

    private class ExcludeElementIterator implements Iterator<Matrix> {
        private final List<Matrix> subData = new ArrayList<>();
        private int currentIndex = 0;

        public ExcludeElementIterator() {
            // Исключаем столбцы
            for (int exclude = 0; exclude < data[0].length; exclude++) {
                List<List<Integer>> curData = new ArrayList<>();
                for (int[] row : data) {
                    List<Integer> curRow = new ArrayList<>();
                    for (int j = 0; j < data[0].length; j++) {
                        if (j != exclude) curRow.add(row[j]);
                    }
                    curData.add(curRow);
                }
                subData.add(new Matrix(curData));
            }

            // Исключаем строки
            for (int exclude = 0; exclude < data.length; exclude++) {
                List<List<Integer>> curData = new ArrayList<>();
                for (int i = 0; i < data.length; i++) {
                    if (i != exclude) {
                        List<Integer> curRow = new ArrayList<>();
                        for (int j = 0; j < data[0].length; j++) {
                            curRow.add(data[i][j]);
                        }
                        curData.add(curRow);
                    }
                }
                subData.add(new Matrix(curData));
            }
        }

        @Override
        public boolean hasNext() {
            return currentIndex < subData.size();
        }

        @Override
        public Matrix next() {
            if (!hasNext()) throw new NoSuchElementException();
            return subData.get(currentIndex++);
        }
    }
}