#include <stdio.h>
#include <stdlib.h>

#define ll long long
#define MAX(a, b) ((a) > (b) ? (a) : (b))

typedef struct SegmentTreeNode
{
    ll max_value;
} SegmentTreeNode;

ll *array;
SegmentTreeNode *tree;
int n;

void build(int node, int start, int end)
{
    if (start == end)
    {
        tree[node].max_value = array[start];
    }
    else
    {
        int mid = (start + end) / 2;
        build(2 * node, start, mid);
        build(2 * node + 1, mid + 1, end);
        tree[node].max_value = MAX(tree[2 * node].max_value, tree[2 * node + 1].max_value);
    }
}

void update(int node, int start, int end, int idx, ll val)
{
    if (start == end)
    {
        array[idx] = val;
        tree[node].max_value = val;
    }
    else
    {
        int mid = (start + end) / 2;
        if (start <= idx && idx <= mid)
        {
            update(2 * node, start, mid, idx, val);
        }
        else
        {
            update(2 * node + 1, mid + 1, end, idx, val);
        }
        tree[node].max_value = MAX(tree[2 * node].max_value, tree[2 * node + 1].max_value);
    }
}

ll query(int node, int start, int end, int l, int r)
{
    if (r < start || end < l)
    {
        return -10000000000LL;
    }
    if (l <= start && end <= r)
    {
        return tree[node].max_value;
    }
    int mid = (start + end) / 2;
    ll p1 = query(2 * node, start, mid, l, r);
    ll p2 = query(2 * node + 1, mid + 1, end, l, r);
    return MAX(p1, p2);
}

int main()
{
    scanf("%d", &n);
    array = (ll *)malloc(n * sizeof(ll));
    tree = (SegmentTreeNode *)malloc(4 * n * sizeof(SegmentTreeNode));
    for (int i = 0; i < n; i++)
    {
        scanf("%lld", &array[i]);
    }
    build(1, 0, n - 1);

    char command[4];
    while (scanf("%s", command))
    {
        if (command[0] == 'E')
        {
            break;
        }
        else if (command[0] == 'M')
        {
            int l, r;
            scanf("%d%d", &l, &r);
            ll result = query(1, 0, n - 1, l, r);
            printf("%lld\n", result);
        }
        else if (command[0] == 'U')
        {
            int idx;
            ll val;
            scanf("%d%lld", &idx, &val);
            update(1, 0, n - 1, idx, val);
        }
    }

    free(array);
    free(tree);
    return 0;
}