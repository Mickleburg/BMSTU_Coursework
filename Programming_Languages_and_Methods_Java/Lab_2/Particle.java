public class Particle {
    private static int counter = 0;
    private final double x, y, z;

    public Particle(double x, double y, double z) {
        this.x = x;
        this.y = y;
        this.z = z;
        counter++;
    }

    public static int getCounter() {
        return counter;
    }

    public double getDist(Particle p) {
        double dx = this.x - p.x;
        double dy = this.y - p.y;
        double dz = this.z - p.z;
        return Math.sqrt(dx * dx + dy * dy + dz * dz);
    }

    public double getX() {return x;}
    public double getY() {return y;}
    public double getZ() {return z;}
}
