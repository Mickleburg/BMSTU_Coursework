#include<stdio.h>
#include<string.h>

int wcount(char *s);

int main() {
    char *s[1000];
    gets(s);
    printf("%d\n", wcount(s));
    return 0;
}

int wcount(char *s){
    int count = 0, in_world = 0;
    while (*s){
        if (*s == ' '){
            in_world = 0;
        }
        else{
            if (in_world == 0){
                count++;
                in_world = 1;
            }
        }
        s++;
    }
    return count;
}