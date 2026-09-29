class Solution {
public:
    string reverseParentheses(string s) {
        stack<int>x;
        vector<pair<int,int>>y;
        for(int i=0;i<s.size();i++){
            if(s[i]=='('){
                x.push(i);
            }else if(s[i]==')'){
                y.push_back({x.top(),i});
                x.pop();
            }
        }
        int n=y.size()-1;
        for(int i=0;i<=n;i++){
            reverse(s.begin()+y[i].first,s.begin()+y[i].second+1);
        }
        string ans="";
        for(char c:s){
            if(c!='(' && c!=')'){
                ans+=c;
            }
        }
        return ans;
    }
};