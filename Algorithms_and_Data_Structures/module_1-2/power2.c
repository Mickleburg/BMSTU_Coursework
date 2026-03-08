#include<stdio.h>
#include<stdlib.h>

unsigned short Check(int x){
    if (x < 0){
        return 0;
    }
    unsigned short cnt = 0;
    x = (unsigned int)x;
    for (unsigned short i = 0; i < 32; i++){
        if ((x >> i) & 1){
            cnt++;
        }
        if (cnt > 1){
            return 0;
        }
    }
    if (cnt == 0){
        return 0;
    }
    return 1;
}

unsigned int Combination(int* arr, unsigned short n, int curr_sum, unsigned short curr_i, unsigned int curr_cnt){
    curr_cnt += Check(curr_sum);

    for (unsigned short i = curr_i + 1; i < n; i++){
        curr_cnt += Combination(arr, n, curr_sum + arr[i], i, 0);
    }
    return curr_cnt;
}

int main(){
    unsigned short n;
    unsigned int cnt = 0;
    scanf("%hu", &n);
    int* arr = (int*)malloc(n * sizeof(int));
    for (unsigned short i = 0; i < n; i++){
        scanf("%d", &arr[i]);
    }

    for (unsigned short i = 0; i < n; i++){
        cnt += Combination(arr, n, arr[i], i, 0);
    }
    printf("%u\n", cnt);
    free(arr);
    return 0;
}