public class ComplexNumber {
    float real, imaginary;

    public ComplexNumber(float real, float imaginary) {
        this.real = real;
        this.imaginary = imaginary;
    }

    public String toString() {
        if (imaginary == 0) {
            return "("+real+")";
        } else if (imaginary < 0) {
            return "("+real+imaginary+"i"+")";
        }
        return "("+real+"+"+imaginary+"i"+")";
    }

    public void add(ComplexNumber other) {
        this.real += other.real;
        this.imaginary += other.imaginary;
    }

    public void subtract(ComplexNumber other) {
        this.real -= other.real;
        this.imaginary -= other.imaginary;
    }

    public void multiply(ComplexNumber other) {
        this.real = this.real * other.real - this.imaginary * other.imaginary;
        this.imaginary = this.real * other.imaginary + other.real * this.imaginary;
    }

    public void divide(ComplexNumber other) {
        float denominator = other.real * other.real + other.imaginary * other.imaginary;
        this.real = (this.real * other.real + this.imaginary * other.imaginary) / denominator;
        this.imaginary = (this.imaginary * other.real - this.real * other.imaginary) / denominator;
    }

    public void setNumber(float real, float imaginary) {
        this.real = real;
        this.imaginary = imaginary;
    }
}
