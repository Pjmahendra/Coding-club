class Solution {
public:
    int appendCharacters(string s, string t) {
        int i=0,j=0;
        while(i<s.size() && j<t.size()){
            if(s[i]==t[j]){
                j++;
            }
            i++;
        }
        if(i==s.size() && j!=t.size())return (t.substr(j,t.size()-j+1)).size();
        if(j==t.size())return 0;
        return 0;
    }
};