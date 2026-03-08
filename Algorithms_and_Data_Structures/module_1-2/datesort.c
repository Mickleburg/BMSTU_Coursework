#include <stdio.h>
#include <stdlib.h>

struct Date {
    int Day, Month, Year;
};

int Key(long m, struct Date date) {
    return m == 31 ? date.Day - 1:
           m == 12 ? date.Month - 1:
           date.Year - 1970;
}

void Distribution_Sort(struct Date *arr, long nel, long m) {
    long *count = (long *)malloc(m * sizeof(long));
    for (long i = 0; i < m; i++) {
        count[i] = 0;
    }

    for (long i = 0; i < nel; i++) {
        count[Key(m, arr[i])]++;
    }

    for (long i = 1; i < m; i++) {
        count[i] += count[i - 1];
    }

    struct Date *arr_new = (struct Date *)malloc(nel * sizeof(struct Date));
    for (long i = nel - 1; i >= 0; i--) {
        int new_i = --count[Key(m, arr[i])];
        arr_new[new_i] = arr[i];
    }

    for (long i = 0; i < nel; i++) {
        arr[i] = arr_new[i];
    }

    free(arr_new);
    free(count);
}

// будем считать каждое поле из Date - разрядом,
// т.е. сортировка будет проходить по трем записям,
// каждая из которых представлена своей с.с. с основаниями 31, 12, 61

void RadixSort(struct Date *arr, long nel) {
    for (size_t i = 0; i < 3; i++) {
        Distribution_Sort(arr, nel, i == 0 ? 31 : i == 1 ? 12 : 61);
    }
}

int main() {
    long n;
    scanf("%ld", &n);
    struct Date *arr = (struct Date *)malloc(n * sizeof(struct Date));
    for (long i = 0; i < n; i++) {
        scanf("%d%d%d", &arr[i].Year, &arr[i].Month, &arr[i].Day);
    }

    RadixSort(arr, n);

    for (long i = 0; i < n; i++) {
        printf("%04d %02d %02d\n", arr[i].Year, arr[i].Month, arr[i].Day);
    }

    free(arr);
    return 0;
}
