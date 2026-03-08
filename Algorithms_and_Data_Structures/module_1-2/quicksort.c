#include<stdio.h>
#include<stdlib.h>

int Partition(int *arr, long low, long high){
    long i = low;
    for (long j = low; j < high; j++){
        if (arr[j] < arr[high]){
            int dop = arr[i];
            arr[i] = arr[j];
            arr[j] = dop;
            i++;
        }
    }
    int dop = arr[i];
    arr[i] = arr[high];
    arr[high] = dop;
    return i;
}

void QuickSortRec(int *arr, long low, long high, long m){
    while (high - low + 1 >= m){
        long q = Partition(arr, low, high);
        if (q - low < high - q){
            QuickSortRec(arr, low, q - 1, m);
            low = q + 1;
        } else{
            QuickSortRec(arr, q + 1, high, m);
            high = q - 1;
        }
    }

    if (high - low + 1 < m){
        for (long j = low + 1; j <= high; j++){
            int key = arr[j];
            long i = j - 1;
            while (i >= low && arr[i] > key){
                arr[i + 1] = arr[i];
                i--;
            }
            arr[i + 1] = key;
        }
    }
}

void QuickSort(int *arr, long n, long m){
    if (n <  2) return;
    QuickSortRec(arr, 0, n - 1, m);
}

int main(){
    size_t n, m;
    scanf("%lu%lu", &n, &m);
    int *arr = (int*)malloc(n * sizeof(int));
    for (size_t i = 0; i < n; i++){
        scanf("%d", &arr[i]);
    }

    QuickSort(arr, n, m);

    for (size_t i = 0; i < n; i++){
        printf("%d ", arr[i]);
    }
    printf("\n");

    free(arr);
    return 0;
}