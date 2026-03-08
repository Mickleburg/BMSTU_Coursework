#include<iostream>
#include<string>

using namespace std;

int main() {
    int t;
    cin >> t;

    while (t--) {
        int n;
        cin >> n;

        string a, b, c;
        cin >> a >> b >> c;

        bool patt = false;
        for (int i = 0; i < n; i++) {
            if (c[i] == a[i] || c[i] == b[i])
            {
                continue;
            }
            patt = true;
        }

        cout << (patt ? "YES" : "NO") << "\n";
    }
}