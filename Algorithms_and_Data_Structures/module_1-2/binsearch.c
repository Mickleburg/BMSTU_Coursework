#include<stdio.h>

unsigned long binsearch(unsigned long nel, int (*compare)(unsigned long i)){
    unsigned long left = 0, right = nel - 1, middle = (left + right) / 2;
    while(left <= right){
        middle = (left + right) / 2;
        switch (compare(middle)){
            case 0:
                return middle;
            case 1:
                right = middle - 1;
                break;
            case -1:
                left = middle + 1;
                break;
        }
    }
    return nel;
}

int main(){
    return 0;
}