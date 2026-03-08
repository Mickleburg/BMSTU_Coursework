#include<stdio.h>

void bubblesort(unsigned long nel,
                int (*compare)(unsigned long i, unsigned long j),
                void (*swap)(unsigned long i, unsigned long j))
{
    long upper_bound = nel - 1, lower_bound = 0, bound, i;
    while (upper_bound > lower_bound){
        bound = upper_bound;
        upper_bound = lower_bound;
        i = lower_bound;
        while ( i < bound){
            if (compare(i, i + 1) == 1){
                swap(i, i + 1);
                upper_bound = i;
            }
            i++;
        }
        bound = lower_bound;
        lower_bound = upper_bound;
        i = upper_bound;
        while (i > bound){
            if (compare(i, i - 1) == -1){
                swap(i, i - 1);
                lower_bound = i;
            }
            i--;
        }
    }

}