import java.util.ArrayList;
import java.util.Iterator;
import java.util.List;

public class SetVec implements Iterable<ThreeVec<Vector>> {
    private final List<Vector> vecs = new ArrayList<>();

    public void addVector(Vector vec) {
        if (vec.lengthSquare() != 0) {
            vecs.add(vec);
        }
    }

    public void removeVector(Vector vec) {
        vecs.remove(vec);
    }

    @Override
    public Iterator<ThreeVec<Vector>> iterator() {
        return new BasisIterator();
    }

    private class BasisIterator implements Iterator<ThreeVec<Vector>>{
        private final List<ThreeVec<Vector>> three = new ArrayList<>();
        private int ind = 0;

        public BasisIterator() {
            List<Vector> copyB = new ArrayList<>(vecs);

            for (Vector v1: copyB) {
                for (Vector v2: copyB) {
                    if (v1 == v2) continue;

                    for (Vector v3: copyB) {
                        if (v3 == v1 || v3 == v2) continue;

                        if (isOrtBasis(v1, v2, v3)) {
                            three.add(new ThreeVec<>(v1, v2, v3));
                        }
                    }
                }
            }
        }
        private boolean isOrtBasis(Vector v1, Vector v2, Vector v3) {
            return v1.Product(v2) == 0 && v1.Product(v3) == 0 && v2.Product(v3) == 0;
        }

        @Override
        public boolean hasNext() {
            return ind < three.size();
        }

        @Override
        public ThreeVec<Vector> next() {
            return three.get(ind++);
        }
    }
}
