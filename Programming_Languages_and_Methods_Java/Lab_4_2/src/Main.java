public class Main {
    public static void main(String[] args) {
        int[][] data = {{1, 2, 3}, {4, 5, 6}, {7, 8, 9}};
        MatrixSubmatrices matrix = new MatrixSubmatrices(data);

        System.out.println("All submatrices:");
        for (MatrixSubmatrices.Matrix sub : matrix) {
            System.out.println(sub);
        }
    }
}