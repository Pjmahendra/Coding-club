class Solution {
public:
    vector<string> topKFrequent(vector<string>& words, int k) {
        map<string,int>mp;
        for(string s:words){
            mp[s]++;
        }
        vector<pair<string,int>>ans(mp.begin(),mp.end());
        sort(ans.begin(),ans.end(),[](const pair<string,int>&a,const pair<string,int>&b){
            if(a.second != b.second)
                return a.second > b.second;
            return a.first < b.first;});
        vector<string>res;
        for(int i=0;i<k;i++){
            res.push_back(ans[i].first);
        }
        return res;
    }
};