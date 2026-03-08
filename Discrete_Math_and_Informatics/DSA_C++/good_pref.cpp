#include <iostream>
#include <vector>

using namespace std;

int main()
{
    int t;
    cin >> t;

    while (t--)
    {
        long long n;
        cin >> n;
        vector<long long> arr(n);
        for (long long i = 0; i < n; ++i)
        {
            cin >> arr[i];
        }

        vector<long long> pref(n);
        pref[0] = arr[0];
        long long max_val = arr[0];
        long long cnt = (pref[0] == 0) ? 1 : 0;

        for (long long i = 1; i < n; ++i)
        {
            pref[i] = pref[i - 1] + arr[i];
            max_val = max(max_val, arr[i]);
            if (max_val == pref[i] - max_val)
            {
                cnt++;
            }
        }

        cout << cnt << "\n";
    }

    return 0;
}
