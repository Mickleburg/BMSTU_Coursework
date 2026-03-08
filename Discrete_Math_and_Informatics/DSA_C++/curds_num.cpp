#include <bits/stdc++.h>
#include <vector>

using namespace std;

vector<vector<int>> myMap;

int main()
{
    ifstream fin("input.txt");
    ofstream fout("output.txt");

    int n;
    fin >> n;

    myMap.resize(5001);

    for (int i = 1; i <= 2 * n; ++i)
    {
        int a;
        fin >> a;
        myMap[a].push_back(i);
    }

    bool possible = true;
    for (int a = 1; a <= 5000; ++a)
    {
        if (myMap[a].size() % 2 != 0)
        {
            possible = false;
            break;
        }
    }

    if (!possible)
    {
        fout << -1 << '\n';
    }
    else
    {
        for (int a = 1; a <= 5000; ++a)
        {
            const vector<int> &vec = myMap[a];
            for (size_t i = 0; i < vec.size(); i += 2)
            {
                fout << vec[i] << ' ' << vec[i + 1] << '\n';
            }
        }
    }

    return 0;
}