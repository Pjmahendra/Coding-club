class Solution {
public:
    vector<long long> distance(vector<int>& nums) {
        map<int,vector<long long>>s;
        for(int i=0;i<nums.size();i++){
            s[nums[i]].push_back(i);
        }
        vector<long long>arr(nums.size(), 0);
        for(auto &[a,b]:s){
            long long sum=0;
            for(int i:b){
                sum+=i;
            }
            long long prefix=0;
            for(int j=0;j<b.size();j++){
                long long i=b[j];
                long long leftsum=prefix;
                long long rightsum=sum-prefix-i;
                long long leftcount=j;
                long long rightcount=b.size()-j-1;
                arr[i]=i*leftcount-leftsum+rightsum-rightcount*i;
                prefix+=i;
            }
        }
        return arr;
    }
};