class Solution {
public:
    vector<string> findRepeatedDnaSequences(string s) {
        vector<string>ans;
        if(s.size()<=10)return ans;
        unordered_map<string,int>m;

        for(int i=0;i<s.size()-9;i++){
            m[s.substr(i,10)]++;
        }
        
        for(auto &[a,b]:m){
            if(b>1)ans.push_back(a);
        }
        return ans;
    }
};