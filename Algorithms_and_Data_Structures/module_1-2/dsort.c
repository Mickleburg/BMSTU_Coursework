#define _Wall_Wextra
#include<stdio.h>
#include<stdlib.h>
#include<string.h>
#define SIZE 26

int main(){
    int count[SIZE] = {0};
    char symbols[1000000];
    scanf("%s", &symbols);
    int nel = strlen(symbols);

    for (int i = 0; i < nel; i++){
        char symbol = symbols[i];
        int key = (int)symbol - 97;
        count[key]++;
    }

    for (int i = 1; i < SIZE; i++){
        count[i] += count[i - 1];
    }

    char *rez = (char*)malloc((nel + 1) * sizeof(char));
    rez[nel] = '\0';
    for (int i = nel - 1; i >= 0; i--){
        char symbol = symbols[i];
        int key = (int)symbol - 97;
        rez[--count[key]] = symbols[i];
    }

    printf("%s\n", rez);

    free(rez);
    return 0;
}