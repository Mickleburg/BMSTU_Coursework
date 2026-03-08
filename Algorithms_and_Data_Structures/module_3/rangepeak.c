#include <stdio.h>
#include <stdlib.h>

#define MAXN 1000000

typedef struct
{
    int sum;
} Node;

int n;
int a[MAXN];
int peaks[MAXN];
Node segtree[4 * MAXN];

int is_peak(int i)
{
    if (n == 1)
        return 1;
    if (i == 0)
    {
        return a[i] >= a[i + 1];
    }
    else if (i == n - 1)
    {
        return a[i] >= a[i - 1];
    }
    else
    {
        return (a[i] >= a[i - 1]) && (a[i] >= a[i + 1]);
    }
}

void build(int node, int left, int right)
{
    if (left == right)
    {
        segtree[node].sum = peaks[left];
    }
    else
    {
        int mid = (left + right) / 2;
        build(2 * node, left, mid);
        build(2 * node + 1, mid + 1, right);
        segtree[node].sum = segtree[2 * node].sum + segtree[2 * node + 1].sum;
    }
}

void update(int node, int left, int right, int idx, int val)
{
    if (left == right)
    {
        segtree[node].sum = val;
    }
    else
    {
        int mid = (left + right) / 2;
        if (idx <= mid)
        {
            update(2 * node, left, mid, idx, val);
        }
        else
        {
            update(2 * node + 1, mid + 1, right, idx, val);
        }
        segtree[node].sum = segtree[2 * node].sum + segtree[2 * node + 1].sum;
    }
}

int query(int node, int left, int right, int l, int r)
{
    if (r < left || right < l)
    {
        return 0;
    }
    if (l <= left && right <= r)
    {
        return segtree[node].sum;
    }
    int mid = (left + right) / 2;
    int p1 = query(2 * node, left, mid, l, r);
    int p2 = query(2 * node + 1, mid + 1, right, l, r);
    return p1 + p2;
}

int main()
{
    scanf("%d", &n);
    for (int i = 0; i < n; i++)
    {
        scanf("%d", &a[i]);
    }

    for (int i = 0; i < n; i++)
    {
        peaks[i] = is_peak(i);
    }

    build(1, 0, n - 1);

    char command[10];
    while (scanf("%s", command))
    {
        if (command[0] == 'E')
        {
            break;
        }
        else if (command[0] == 'P')
        {
            int l, r;
            scanf("%d%d", &l, &r);
            int result = query(1, 0, n - 1, l, r);
            printf("%d\n", result);
        }
        else if (command[0] == 'U')
        {
            int i, v;
            scanf("%d%d", &i, &v);
            a[i] = v;
            int indices[3] = {i - 1, i, i + 1};
            for (int idx = 0; idx < 3; idx++)
            {
                int pos = indices[idx];
                if (pos >= 0 && pos < n)
                {
                    int old_peak = peaks[pos];
                    peaks[pos] = is_peak(pos);
                    if (old_peak != peaks[pos])
                    {
                        update(1, 0, n - 1, pos, peaks[pos]);
                    }
                }
            }
        }
    }

    return 0;
}