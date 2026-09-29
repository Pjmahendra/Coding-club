class Solution {
public:
    int maxDepth(string s) {
        int ans=0;
        int x=0;
        for(int i=0;i<s.size();i++){
            if(s[i]!='(' && s[i]!=')'){continue;}
            if(s[i]=='('){
                x++;
            }else{
                x--;
            }
            ans=max(ans,x);
        }
        return ans;
    }
};