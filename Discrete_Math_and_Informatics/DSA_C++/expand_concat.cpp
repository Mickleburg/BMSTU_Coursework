#include<iostream>
#include<string>

using namespace std;

int main() {
    int t;
    cin >> t;
    while(t--) {
        int n, k;
        cin >> n >> k;

        string s;
        cin >> s;

        bool verdict = true;
        for (int i = 0; i < n / 2; i++) {
            if (s[i] != s[n - i - 1]) {
                verdict = false;
                break;
            }
        }

        if (verdict || k < 1) {
            cout << 1 << "\n";
        } else {
            cout << 2 << "\n";
        }
    }
}