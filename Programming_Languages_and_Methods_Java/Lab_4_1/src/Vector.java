public class Vector {
    private final int x;
    private final int y;
    private final int z;

    public Vector(int x, int y, int z) {
        this.x = x;
        this.y = y;
        this.z = z;
    }

    public int Product(Vector o) {
        return this.x * o.x + this.y * o.y + this.z * o.z;
    }

    public int lengthSquare() {
        return x * x + y * y + z * z;
    }

    public boolean equals(Vector o) {
        if (this == o) return true;
        if (o == null) return false;
        return this.x == o.x && this.y == o.y && this.z == o.z;
    }

    @Override
    public String toString() {
        return String.format("(%d, %d, %d)", x, y, z);
    }
}
