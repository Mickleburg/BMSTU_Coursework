#include <stdio.h>
#include <stdlib.h>

#define MAXN 300000

typedef long long ll;

int n, m;
ll arr[MAXN];
ll segtree[4 * MAXN];

ll gcd(ll a, ll b)
{
    if (b == 0)
        return llabs(a);
    return gcd(b, a % b);
}

void build(int node, int left, int right)
{
    if (left == right)
    {
        segtree[node] = arr[left];
    }
    else
    {
        int mid = (left + right) / 2;
        build(2 * node, left, mid);
        build(2 * node + 1, mid + 1, right);
        segtree[node] = gcd(segtree[2 * node], segtree[2 * node + 1]);
    }
}

ll query(int node, int left, int right, int l, int r)
{
    if (r < left || right < l)
    {
        return 0;
    }
    if (l <= left && right <= r)
    {
        return segtree[node];
    }
    int mid = (left + right) / 2;
    ll left_gcd = query(2 * node, left, mid, l, r);
    ll right_gcd = query(2 * node + 1, mid + 1, right, l, r);
    return gcd(left_gcd, right_gcd);
}

int main()
{
    scanf("%d", &n);
    for (int i = 0; i < n; i++)
    {
        scanf("%lld", &arr[i]);
    }
    build(1, 0, n - 1);

    scanf("%d", &m);
    for (int i = 0; i < m; i++)
    {
        int l, r;
        scanf("%d%d", &l, &r);
        ll result = query(1, 0, n - 1, l, r);
        printf("%lld\n", result);
    }

    return 0;
}