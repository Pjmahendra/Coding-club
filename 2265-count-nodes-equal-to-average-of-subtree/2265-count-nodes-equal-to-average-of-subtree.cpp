/**
 * Definition for a binary tree node.
 * struct TreeNode {
 *     int val;
 *     TreeNode *left;
 *     TreeNode *right;
 *     TreeNode() : val(0), left(nullptr), right(nullptr) {}
 *     TreeNode(int x) : val(x), left(nullptr), right(nullptr) {}
 *     TreeNode(int x, TreeNode *left, TreeNode *right) : val(x), left(left), right(right) {}
 * };
 */
class Solution {
public:
    int n=0;
    pair<int,int> avg(TreeNode* root){
        if(!root)return {0,0};
        pair<int,int> a=avg(root->left);
        pair<int,int> b=avg(root->right);
        if((root->val+a.first+b.first)/(1+a.second+b.second)==root->val)n++;
        return {root->val+a.first+b.first,1+a.second+b.second};
    }
    int averageOfSubtree(TreeNode* root) {
        pair<int,int>ans=avg(root);
        return n;
    }
};