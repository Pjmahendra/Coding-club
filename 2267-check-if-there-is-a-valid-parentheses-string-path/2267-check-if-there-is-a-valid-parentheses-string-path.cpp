class Solution {
public:
    bool check(vector<vector<char>>&grid,int m,int n,int i,int j,int o,int c){
        if( i>=m || j>=n)return false;
        if((m+n-1)%2!=0 ){
            return false;
        }
        if(grid[0][0]!='('){
            return false;
        }
        vector<vector<vector<bool>>>dp(
            m,vector<vector<bool>>(n,vector<bool>(m+n,false))
        );
        dp[0][0][1] = true;
        for(int i=0;i<m;i++){
            for(int j=0;j<n;j++){
                for(int bal=0;bal<=m+n;bal++){
                    if(!dp[i][j][bal])continue;
                    if(i+1<m){
                        int newbal=bal;
                        if(grid[i+1][j]=='('){
                            newbal++;
                        }else newbal--;
                        if(newbal>=0)dp[i+1][j][newbal]=true;
                    }
                    if(j+1<n){
                        int newbal=bal;
                        if(grid[i][j+1]=='('){
                            newbal++;
                        }else newbal--;
                        if(newbal>=0)dp[i][j+1][newbal]=true;
                    }
                }
            }
        }
        return dp[m-1][n-1][0];

    }
    bool hasValidPath(vector<vector<char>>& grid) {
        return check(grid,grid.size(),grid[0].size(),0,0,0,0);
    }
};