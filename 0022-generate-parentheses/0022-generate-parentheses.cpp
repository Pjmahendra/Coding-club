class Solution {
public:
    vector<string> result;
    void per(int o,int c,string ans ,int n){
        if(o==c && o+c==2*n){
            result.push_back(ans);
        }
        if(o<n)
            per(o+1,c,ans + '(',n);
        if(c<o)
            per(o,c+1,ans+')',n);

        
    }
    vector<string> generateParenthesis(int n) {
        per(0,0,"",n);
        return result;
    }
};