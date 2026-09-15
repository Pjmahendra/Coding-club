class Solution {
public:
    bool is(string &s,int l,int r){
        while(l<r){
            if(s[l]!=s[r])return false;
            l++;r--;
        }
        return true;
    }
    int maxPalindromes(string s, int k) {
        int n=s.size();
        int ans=0,end=-1;
        for(int i=0;i<n;i++){
            int x=0;
            for(int j=end+1;j<=i-k+1;j++){
                if(is(s,j,i)){
                    ans++;
                    end=i;
                    break;
                }x++;
            }
        }
        return ans;
    }
};