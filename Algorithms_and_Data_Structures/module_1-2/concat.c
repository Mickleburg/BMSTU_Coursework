#include<stdio.h>
#include<stdlib.h>
#include<string.h>
#define default_len 1001

char* concat(char** s, int n);
char** Input_Arr_S(int n);
void Clear_Memory(char** arr_s, int n, char* s);

int main(){
    int n;
    scanf("%d", &n);
    char** s = Input_Arr_S(n);
    char* s_rez = concat(s, n);
    printf("%s\n", s_rez);
    Clear_Memory(s, n, s_rez);
    return 0;
}

char* concat(char** s, int n){
    unsigned long sum_len = 0;
    for (int i = 0; i < n; i++){
        sum_len += strlen(s[i]);
    }
    char* rez_s = (char*)malloc((++sum_len) * sizeof(char));
    for (int i = 0; i < n; i++){
        strcat(rez_s, s[i]);
    }
    return rez_s;
}

char** Input_Arr_S(int n){
    char** arr_s = (char**)malloc(n * sizeof(char*));
    for (int i = 0; i < n; i++){
        arr_s[i] = (char*)malloc(default_len * sizeof(char));
        scanf("%s", arr_s[i]);
    }
    return arr_s;
}

void Clear_Memory(char **arr_s, int n, char *s)
{
    free(s);
    for (int i = 0; i < n; i++)
    {
        free(arr_s[i]);
    }
    free(arr_s);
}