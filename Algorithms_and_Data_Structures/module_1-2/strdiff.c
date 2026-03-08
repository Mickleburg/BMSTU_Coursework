#include<stdio.h>
#include<string.h>
#define min(a, b) ((a < b) ? a: b)

int strdiff(char *a, char *b);

int main(){
    char *st1 = "aa", *st2 = "ai";
    printf("%d\n", strdiff(st1, st2));
    return 0;
}

int strdiff(char *a, char *b){
    int len_a = strlen(a) + 1, len_b = strlen(b) + 1;
    for (int i = 0; i < min(len_a, len_b); i++){
        for (int j = 0; j < 8; j++){
            if (((a[i]>>j) & 1) != ((b[i]>>j) & 1)){
                return 8 * i + j;
            }
        }
    }
    return -1;
}
