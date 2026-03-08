#include<stdio.h>
#include<stdlib.h>
#include<string.h>

int main(int argc, char **argv){
    if (argc <= 3){
        printf("Usage: frame <height> <width> <text>\n");
        return 0;
    }
    char *text = argv[3];
    int len_text = strlen(text);
    int height = strtol(argv[1], NULL, 10);
    int width = strtol(argv[2], NULL, 10);
    if ((height <= 2) || (len_text > width - 2)){
        printf("Error\n");
        return 0;
    }
    int i_text = (height - 1) / 2;
    int j_start_text = (width - len_text) / 2;
    int j_end_text = (width - len_text) / 2 + len_text;

    for (int i = 0; i < height; i++){
        for (int j = 0; j < width; j++){
            if ((i == 0) || (i == height - 1) || (j == 0) || (j == width - 1)){
                printf("*");
                continue;
            }
            if ((i == i_text) & (j >= j_start_text) & (j < j_end_text)){
                printf("%c", text[j - j_start_text]);
                continue;
            }
            printf(" ");
        }
        printf("\n");
    }
}