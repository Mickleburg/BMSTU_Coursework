#include<stdio.h>
#include<stdlib.h>

void Merge(size_t low, size_t mid, size_t high, long* arr, long *buffer)
{
    size_t i = low, j = mid + 1, h = low;

    while (i <= mid && j <= high){
        if (abs(arr[i]) <= abs(arr[j])){
            buffer[h++] = arr[i++];
        } else{
            buffer[h++] = arr[j++];
        }
    }

    while (i <= mid){
        buffer[h++] = arr[i++];
    }

    while(j <= high){
        buffer[h++] = arr[j++];
    }

    for (size_t k = low; k <= high; k++){
        arr[k] = buffer[k];
    }
}

void Insertion_Sort(size_t low, size_t high, long *arr)
{
    for (size_t i = low + 1; i <= high; i++){
        long x = arr[i];
        long j = i - 1;
        while (j >= (long)low && abs(arr[j]) > abs(x)){
            arr[j + 1] = arr[j];
            j--;
        }
        arr[j + 1] = x;
    }
}

void Merge_Sort_Rec_m(size_t low, size_t high, long *arr, long *buffer)
{
    if (low >= high){return;}

    if (high - low < 5){
        Insertion_Sort(low, high, arr);
        return;
    }

    size_t med = (low + high) / 2;
    Merge_Sort_Rec_m(low, med, arr, buffer);
    Merge_Sort_Rec_m(med + 1, high, arr, buffer);

    Merge(low, med, high, arr, buffer);
}

void Merge_Sort(size_t nel, long *arr)
{
    if (nel < 2){return;}
    long *buffer = (long*)malloc(nel * sizeof(long));
    Merge_Sort_Rec_m(0, nel - 1, arr, buffer);
    free(buffer);
}

int main(){
    size_t nel;
    scanf("%lu", &nel);
    long *arr = (long*)malloc(nel * sizeof(long));
    for (size_t i = 0; i < nel; i++){
        scanf("%ld", &arr[i]);
    }

    Merge_Sort(nel, arr);

    for (size_t i = 0; i < nel; i++){
        printf("%ld ", arr[i]);
    }
    printf("\n");

    free(arr);
    return 0;
}