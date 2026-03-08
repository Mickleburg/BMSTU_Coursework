public class Main {
    public static void main(String[] args) {
        SetVec vectorSet = new SetVec();

        vectorSet.addVector(new Vector(1, 0, 0));
        vectorSet.addVector(new Vector(0, 1, 0));
        vectorSet.addVector(new Vector(0, 0, 1));
        vectorSet.addVector(new Vector(0, 1, 1));

        System.out.println("Все тройки ортогональных базисов:");
        for (ThreeVec<Vector> three : vectorSet) {
            System.out.println(three);
        }

        vectorSet.removeVector(new Vector(0, 1, 1));

        System.out.println("\nПосле удаления негодного вектора:");
        for (ThreeVec<Vector> three : vectorSet) {
            System.out.println(three);
        }
    }
}
