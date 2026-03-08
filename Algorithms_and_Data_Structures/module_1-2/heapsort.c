#include<stdio.h>
#include<string.h>
#include<stdlib.h>

#define _Wall_Wextra
#define SIZE 1000

int Count_a(char* str){
    int cnt = 0;
    while(*str){
        if ((*str) == 'a'){
            cnt++;
        }
        str++;
    }
    return cnt;
}

int Compare_str(const void* a, const void* b){
    return Count_a(*(char**)a) - Count_a(*(char**)b);
}

void swap(void *a, void *b, unsigned int width){
    void *temp = (void*)malloc(width);
    memcpy(temp, a, width);
    memcpy(a, b, width);
    memcpy(b, temp, width);
    free(temp);
}

void Heapify(unsigned int i, unsigned int nel,
             void* base, size_t width,
             int (*compare)(const void* a, const void *b))
{
    unsigned int left, right, temp;
    while (1){
        left = 2 * i + 1;
        right = 2 * i + 2;
        temp = i;
        if (left < nel && compare((char*)base + i * width, (char*)base + left * width) < 0){
            i = left;
        }
        if (right < nel && compare((char*)base + i * width, (char*)base + right * width) < 0){
            i = right;
        }
        if (i == temp){
            break;
        }
        swap((char*)base + i * width, (char*)base + temp * width, width);
    }
}

void Build_Heap(size_t nel, void* base, size_t width,
                int (*compare)(const void *a, const void *b))
{
    for (size_t i = nel / 2; i > 0; i--){
        Heapify(i - 1, nel, base, width, compare);
    }
}

void hsort(void *base, size_t nel, size_t width,
           int (*compare)(const void *a, const void *b))
{
    Build_Heap(nel, base, width, compare);

    for (size_t i = nel - 1; i > 0; i--){
        swap(base, (char*)base + i * width, width);
        Heapify(0, i, base, width, compare);
    }
}

int main(){
    unsigned int len;
    scanf("%u", &len);
    char** arr_str = (char**)malloc(len * sizeof(char*));
    for (unsigned int i = 0; i < len; i++){
        arr_str[i] = (char*)malloc(SIZE * sizeof(char));
        scanf("%s", arr_str[i]);
    }

    hsort(arr_str, len, sizeof(char*), Compare_str);

    for (unsigned int i = 0; i < len; i++){
        printf("%s ", arr_str[i]);
        free(arr_str[i]);
    }
    printf("\n");

    free(arr_str);
    return 0;
}
