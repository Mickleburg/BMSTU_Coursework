import java.util.Scanner;

public class Test {
    public static void main(String[] args) {
        Scanner scanner = new Scanner(System.in);
        Universe universe = new Universe();

        System.out.print("Enter the number of particles: ");
        int count = scanner.nextInt();

        Particle[] allParticles = new Particle[count];

        for (int i = 0; i < count; i++) {
            System.out.println("Enter particle no." + (i + 1) + ":");
            System.out.print("X coordinate: ");
            double x = scanner.nextDouble();
            System.out.print("Y coordinate: ");
            double y = scanner.nextDouble();
            System.out.print("Z coordinate: ");
            double z = scanner.nextDouble();

            allParticles[i] = new Particle(x, y, z);
        }

        double maxDist = 0;
        for (int i = 0; i < count; i++) {
            for (int j = i + 1; j < count; j++) {
                double dist = allParticles[i].getDist(allParticles[j]);
                if (dist > maxDist) {
                    maxDist = dist;
                }
            }
        }

        System.out.println("Maximum distance between particles: " + maxDist);
        System.out.println("The universe contains everything " + Particle.getCounter() + " particles");

        scanner.close();
    }
}
