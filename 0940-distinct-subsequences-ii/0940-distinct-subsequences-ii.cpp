class Solution {
public:
    int distinctSubseqII(string s) {
        long long mod = 1000000007;
        long long dp=0;
        long long m[26]={};
        for(int i=0;i<s.size();i++){
            long long prev=dp;
            dp=(2*dp+1-m[s[i]-'a']+mod)%mod;
            m[s[i]-'a']=(prev+1)%mod;
        }
        return dp;

    }
};