class Solution {
public:
    int minInsertions(string s) {
        stack<char>st;
        int count=0;
        for(int i=0;i<s.size();i++){
            if(s[i]=='('){
                st.push(s[i]);
            }
            else{
                if(!st.empty()){
                    st.pop();
                }else{
                    count++;
                }
                if(i+1>=s.size() || s[i+1]!=')'){
                    count++;
                }else{
                    i++;
                }
            }
        }
        count+=2*st.size();
        return count;
    }
};