void Shellsort_fib(unsigned long nel,
                   int (*compare)(unsigned long i, unsigned long j),
                   void (*swap)(unsigned long i, unsigned long j),
                   long fib1, long fib2)
{
    long d = fib2;
    for (long i_start = d; i_start < nel; i_start++)
    {
        long i = i_start;
        while (i >= d && (compare(i - d, i) > 0))
        {
            swap(i - d, i);
            i -= d;
        }
    }

    // Понял, спасибо
    long current = fib2;
    fib2 = fib1;
    fib1 = current - fib1;

    if (fib1 > 0)
    {
        Shellsort_fib(nel, compare, swap, fib1, fib2);
    }
}

void shellsort(unsigned long nel,
               int (*compare)(unsigned long i, unsigned long j),
               void (*swap)(unsigned long i, unsigned long j))
{
    if (nel > 1)
    {
        long fib1 = 1, fib2 = 1, current;
        while (fib1 + fib2 < nel)
        {
            current = fib2;
            fib2 += fib1;
            fib1 = current;
        }
        Shellsort_fib(nel, compare, swap, fib1, fib2);
    }
}
