class Solution {
public:
    string evaluate(string s, vector<vector<string>>& knowledge) {
        unordered_map<string,string>mp;
        for(auto &a:knowledge){
            mp[a[0]]=a[1];
        }
        for(int i=0;i<s.size();i++){
            if(s[i]=='('){
                int start=i;
                i++;
                string x="";
                while(s[i]!=')'){
                    x+=s[i];
                    i++;
                }
                string value = mp.count(x) ? mp[x] : "?";
                s.replace(start,i-start+1,value);
                i = start + value.size() - 1;
            }
        }
        return s;
    }
};