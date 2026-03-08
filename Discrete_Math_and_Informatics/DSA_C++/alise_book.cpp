#include<iostream>
#include<vector>

using namespace std;

int main() {
    int t;
    cin >> t;
    while (t--) {
        int n;
        cin >> n;

        long long el, my_max = 0;
        for (int i = 0; i < n - 1; i++) {
            cin >> el;
            my_max = max(my_max, el);
        }

        cin >> el;

        cout << el + my_max << "\n";
    }
}