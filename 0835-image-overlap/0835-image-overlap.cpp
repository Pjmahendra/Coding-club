class Solution {
public:
    int largestOverlap(vector<vector<int>>& img1, vector<vector<int>>& img2) {
        int n=img1.size();
        vector<vector<int>>A,B;
        for(int i=0;i<n;i++){
            for(int j=0;j<n;j++){
                if(img1[i][j]==1)A.push_back({i,j});
                if(img2[i][j]==1)B.push_back({i,j});
            }
        }
         map<pair<int,int>, int> m;
        int count=0;
        for(vector<int> a:A){
            for(vector<int>b:B){
                int dx=a[0]-b[0];
                int dy=a[1]-b[1];
                m[{dx,dy}]++;
                count=max(count,m[{dx,dy}]);
            }
        }
        return count;
    }
};