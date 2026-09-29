class Solution {
public:
    string frequencySort(string s) {
        unordered_map<char,int>ap;
        for(char c:s){
            ap[c]++;
        }
        vector<pair<char,int>>x(ap.begin(),ap.end());
        sort(x.begin(),x.end(),[](const auto &a,const auto &b){
            return a.second>b.second;
        });
        string ans="";
        for(auto &[a,b]:x){
            while(b--){
                ans+=a;
            }
        }
        return ans;
    }
};