#include<stdio.h>

unsigned long peak(unsigned long nel, int (*less)(unsigned long i, unsigned long j)){
    switch (nel) {
    case 1:
        return 0;
    case 2:
        return !less(0, 1) ? 0 : 1;
    default:
        for (unsigned long i = 0; i < nel - 2; i++) {
            if (!less(i + 1, i) && !less(i + 1, i + 2)) {
                return i + 1;
            }
        }
        return !less(0, 1) ? 0 : nel - 1;
    }
}
