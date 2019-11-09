#include <bits/stdc++.h>
using namespace std;
int n,m;
int w[101],c[101];
int a[101][10009];
void print(int x,int y)
{
    if (a[x][y]==0)
        return;
    if (a[x-1][y]==a[x][y])
        print(x-1,y);
    else
    {
        print(x-1,y-w[x]);
        cout<<x<<endl;
    }
}
int main()
{
    cin>>n>>m;
    for (int i=1;i<=n;i++)
    {
        cin>>w[i];
    }
    for (int i=1;i<=n;i++)
    {
        cin>>c[i];
    }
    for (int i=1;i<=n;i++)
    {
        for (int j=0;j<=m;j++)
        {
            a[i][j]=a[i-1][j];
            if (w[i]<=j)
                a[i][j]=max(a[i][j],a[i-1][j-w[i]]+c[i]);
        }
    }
    print(n,m);

    return 0;
}