public class Vector3D implements Comparable<Vector3D>{
    private double x;
    private double y;
    private double z;

    public Vector3D(double x, double y, double z) {
        this.x = x;
        this.y = y;
        this.z = z;
    }

    public double length() {
        return Math.sqrt(x*x + y*y + z*z);
    }

    public double angleWithXOY() {
        return this.z / this.length();
    }

    public int compareTo(Vector3D other) {

        if (this.length() == 0 && other.length() == 0) {
            return 0;
        } else if (this.length() == 0) {
            return -1;
        } else if (other.length() == 0) {
            return 1;
        }

        if (this.angleWithXOY() < other.angleWithXOY()) {
            return -1;
        } else if (this.angleWithXOY() > other.angleWithXOY()) {
            return 1;
        } else {
            return 0;
        }
    }

    public String toString() {
        return String.format("(%.2f, %.2f, %.2f)", x, y, z);
    }
}
