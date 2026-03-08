#define _Wall_Wextra

#include<stdio.h>
#include<stdlib.h>

union Int32 {
    int x;
    unsigned char bytes[4];
};

int Key(unsigned char bytes[4], int r){
    return r < 3 ? bytes[r] :
           bytes[r] > 127 ? bytes[r] - 128 :
           bytes[r] + 128;
}

void DistributionSort(union Int32 *arr, long nel, int r){
    long count[256] = {0};

    for (long i = 0; i < nel; i++){
        count[Key(arr[i].bytes, r)]++;
    }

    for (long i = 1; i < 256; i++){
        count[i] += count[i - 1];
    }

    union Int32 *arr_new = (union Int32*)malloc(nel * sizeof(union Int32));
    for (long i = nel - 1; i >= 0; i--){
        int new_i = --count[Key(arr[i].bytes, r)];
        arr_new[new_i] = arr[i];
    }

    for (long i = 0; i < nel; i++){
        arr[i] = arr_new[i];
    }

    free(arr_new);
}

void RadixSort(union Int32 *arr, long nel){
    for (int r = 0; r < 4; r++){
        DistributionSort(arr, nel, r);
    }
}

int main(){
    long nel;
    scanf("%ld", &nel);
    union Int32 *arr = (union Int32*)malloc(nel * sizeof(union Int32));
    for (long i = 0; i < nel; i++){
        scanf("%d", &arr[i].x);
    }

    RadixSort(arr, nel);

    for (long i = 0; i < nel; i++){
        printf("%d ", arr[i].x);
    }
    printf("\n");

    free(arr);
    return 0;
}
