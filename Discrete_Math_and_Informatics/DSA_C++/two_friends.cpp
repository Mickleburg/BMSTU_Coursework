#include<iostream>
#include<vector>

using namespace std;

struct el {
    int x;
    bool flag;

    el(int get_x) : x(get_x), flag(false) {}
};

int main() {
    int t;
    cin >> t;
    while(t--) {
        int n;
        cin >> n;

        vector<el> vec;
        for (int i = 0; i < n; i++) {
            int x;
            cin >> x;
            vec.push_back(el(--x));
        }

        int min_k = 3;
        for (int i = 0; i < n; i++) {
            if (!vec[i].flag){
                int i_start = i, cnt = 0;

                while (i_start != i || cnt == 0) {
                    vec[i_start].flag = true;
                    i_start = vec[i_start].x;
                    cnt++;
                }

                if (cnt == 2) {
                    min_k = 2;
                    break;
                }
            }
        }

        cout << min_k << '\n';
    }
}