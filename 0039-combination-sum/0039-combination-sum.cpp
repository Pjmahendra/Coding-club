class Solution {
public:
    void backtrack(vector<int>&cand,int target,int s,int sum,vector<int>&ans,vector<vector<int>>&res){
        if(sum==target){
            res.push_back(ans);
            return;
        }
        if(sum > target) return;
        if(s==cand.size())return ;
        for(int i=s;i<cand.size();i++){
            sum+=cand[i];
            ans.push_back(cand[i]);
            backtrack(cand,target,i,sum,ans,res);
            ans.pop_back();
            sum-=cand[i];
            
        }

    }
    vector<vector<int>> combinationSum(vector<int>& candidates, int target) {
        vector<vector<int>>res;
        vector<int>ans;
        backtrack(candidates,target,0,0,ans,res);
        return res;
    }
};