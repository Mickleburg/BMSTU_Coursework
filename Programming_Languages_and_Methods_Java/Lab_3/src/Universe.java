public class Universe {
    private final String name;
    private final int numberOfPlanets;
    private final double averageMass;

    public Universe(String name, int numberOfPlanets, double averageMass) {
        this.name = name;
        this.numberOfPlanets = numberOfPlanets;
        this.averageMass = averageMass;
    }

    public String getName() {
        return name;
    }

    public int getNumberOfPlanets() {
        return numberOfPlanets;
    }

    public double getAverageMass() {
        return averageMass;
    }

    @Override
    public String toString() {
        return "Universe{" +
                "name='" + name + '\'' +
                ", planets=" + numberOfPlanets +
                ", avgMass=" + averageMass +
                '}';
    }
}