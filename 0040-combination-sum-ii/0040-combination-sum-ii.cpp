class Solution {
public:
    void backtrack(vector<int>&candidates,int &target,int sum,int i,vector<int>&ans,vector<vector<int>>&res){
        if(sum==target){
            res.push_back(ans);
            return;
        }
        if(sum>target)return;
        if(i==candidates.size())return;
        for(int x=i;x<candidates.size();x++){
            if(x>i && candidates[x]==candidates[x-1])continue;
            sum+=candidates[x];
            ans.push_back(candidates[x]);
            backtrack(candidates,target,sum,x+1,ans,res);
            sum-=candidates[x];
            ans.pop_back();
        }
    }
    vector<vector<int>> combinationSum2(vector<int>& candidates, int target) {
        vector<vector<int>>res;
        vector<int>ans;
        sort(candidates.begin(),candidates.end());
        backtrack(candidates,target,0,0,ans,res);
        return res;
    }
};