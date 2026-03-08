#include<iostream>

using namespace std;

int main() {
    int t;
    cin >> t;

    while(t--) {
        int n, k;
        cin >> n >> k;

        for (int i = 0; i < n; i++) {
            for (int j = 0; j < k; j++) {
                char letter = 97 + j;
                cout << letter;
            }
        }
        cout << "\n";
    }
}