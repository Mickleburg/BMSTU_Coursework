#include<iostream>
#include<vector>

using namespace std;

int main() {
    int t;
    cin >> t;
    while (t--) {
        int n, cnt = 0;
        cin >> n;

        vector<long long> arr_a(n);
        for (int i = 0; i < n; i++) {
            cin >> arr_a[i];
        }

        long long el;
        for (int i = 0, a_i = 0; i < n; i++) {
            cin >> el;

            if (arr_a[a_i] <= el) {
                a_i++;
                continue;
            }
            cnt++;
        }

        cout << cnt << endl;
    }
}