#include <stdio.h>
#include <stdlib.h>
#include <math.h>

#define INF 1e18

int main()
{
    int n;
    scanf("%d", &n);

    double *logValues = (double *)malloc(n * sizeof(double));
    int *zeros = (int *)malloc(n * sizeof(int));

    for (int i = 0; i < n; i++)
    {
        int a, b;
        scanf("%d/%d", &a, &b);
        if (a == 0)
        {
            logValues[i] = -INF;
            zeros[i] = 1;
        }
        else
        {
            logValues[i] = log((double)a / b);
            zeros[i] = 0;
        }
    }

    double max_so_far = -INF;
    double max_ending_here = 0;
    int max_start = 0, max_end = 0;
    int s = 0;

    for (int i = 0; i < n; i++)
    {
        if (zeros[i])
        {
            max_ending_here = 0;
            s = i + 1;
            continue;
        }
        max_ending_here += logValues[i];

        if (max_ending_here > max_so_far)
        {
            max_so_far = max_ending_here;
            max_start = s;
            max_end = i;
        }
        if (max_ending_here < 0)
        {
            max_ending_here = 0;
            s = i + 1;
        }
    }

    printf("%d %d\n", max_start, max_end);

    free(logValues);
    free(zeros);

    return 0;
}