#include<stdio.h>
#include<string.h>
#include<math.h>
#include<stdlib.h>
unsigned int min(unsigned int a, unsigned int b);
unsigned int default_len_st = 100;
unsigned int String_Match(char** arr_st, unsigned short i_st, unsigned short n, unsigned int check, int k, unsigned int** arr_i);
unsigned int Index_Match(char *str_1, char *str_2, unsigned int len_st_1);

int main(){
    unsigned short n;
    scanf("%hu", &n);
    unsigned int st_check = 0, min_d = default_len_st * n;
    char** arr_st = (char**)malloc(n * sizeof(char*));
    unsigned int** arr_match = (unsigned int**)malloc(n * sizeof(unsigned int**));
    for (unsigned short i = 0; i < n; i++){
        arr_st[i] = (char*)malloc(default_len_st * sizeof(char));
        scanf("%s", arr_st[i]);
        arr_match[i] = (unsigned int*)malloc(n * sizeof(unsigned int));
    }
    for (unsigned short i = 0; i < n; i++){
        for (unsigned short j = 0; j < n; j++){
            arr_match[i][j] = Index_Match(arr_st[i], arr_st[j], strlen(arr_st[i]));
        }
    }

    for (unsigned short i_st = 0; i_st < n; i_st++){
        min_d = min(min_d, strlen(arr_st[i_st]) +
        String_Match(arr_st, i_st, n, st_check + pow(2, i_st), n - 1, arr_match));
    }
    printf("%u\n", min_d);

    for (unsigned short i = 0; i < n; i++){
        free(arr_st[i]);
        free(arr_match[i]);
    }
    free(arr_st);
    free(arr_match);
    return 0;
}

unsigned int String_Match(char **arr_st, unsigned short i_st, unsigned short n, unsigned int check, int k, unsigned int** arr_i){
    if (k == 0){
        return 0;
    }
    unsigned int len_1 = strlen(arr_st[i_st]), i_start, min_d = default_len_st * n;
    for (unsigned short i_end = 0; i_end < n; i_end++){
        if (!(1 & (check >> i_end))){
            min_d = min(min_d, arr_i[i_st][i_end] +
            String_Match(arr_st, i_end, n, check + pow(2, i_end), k - 1, arr_i));
        }
    }
    return min_d;
}

unsigned int Index_Match(char* str_1, char* str_2, unsigned int len_st_1){
    for (unsigned int i = 1; i < len_st_1; i++){
        if (strncmp(str_1 + sizeof(char) * i, str_2, len_st_1 - i) == 0){
            return strlen(str_2) - (len_st_1 - i);
        }
    }
    return strlen(str_2);
}

unsigned int min(unsigned int a, unsigned int b){
    return a <= b ? a : b;
}
