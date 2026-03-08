#include<stdio.h>
#include<stdlib.h>
#include<string.h>

void revarray(void* base, size_t nel, size_t width){
    unsigned char* start = (unsigned char*)base;
    unsigned char* end = start + (nel - 1) * width;
    unsigned char* buff = (unsigned char*)malloc(nel * width);

    for (size_t i = 0; i < nel / 2; i++){
        memcpy(buff, start + i * width, width);
        memcpy(start + i * width, end - i * width, width);
        memcpy(end - i * width, buff, width);
    }
    free(buff);
}

int main(){
    long arr[5] = {89, 32, 0, -7, -8};

    revarray(arr, sizeof(arr) / sizeof(long), sizeof(long));

    for (size_t i = 0; i < sizeof(arr) / sizeof(long); ++i){
        printf("%ld ", arr[i]);
    }
    return 0;
}