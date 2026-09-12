class Solution {
public:
    bool containsNearbyDuplicate(vector<int>& nums, int k) {
        unordered_map<int,vector<int>>m;
        for(int i=0;i<nums.size();i++){
            m[nums[i]].push_back(i);
        }
        for(auto &[a,b]:m){
            if(b.size()<2)continue;
            for(int i=0;i<b.size();i++){
                for(int j=i+1;j<b.size();j++){
                    if(b[j]-b[i] <= k)return true;
                }
            }
        }
        return false;
    }
};