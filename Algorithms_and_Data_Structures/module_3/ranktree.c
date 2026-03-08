#include <stdio.h>
#include <stdlib.h>
#include <string.h>

typedef struct TreeNode
{
    int key;
    char value[10];
    int count;
    struct TreeNode *left, *right;
} TreeNode;

TreeNode *createNode(int key, const char *value)
{
    TreeNode *node = (TreeNode *)malloc(sizeof(TreeNode));
    node->key = key;
    strcpy(node->value, value);
    node->count = 1;
    node->left = NULL;
    node->right = NULL;
    return node;
}

void updateCount(TreeNode *node)
{
    if (node)
    {
        int leftCount = node->left ? node->left->count : 0;
        int rightCount = node->right ? node->right->count : 0;
        node->count = 1 + leftCount + rightCount;
    }
}

TreeNode *insert(TreeNode *root, int key, const char *value)
{
    if (root == NULL)
        return createNode(key, value);

    if (key < root->key)
        root->left = insert(root->left, key, value);
    else if (key > root->key)
        root->right = insert(root->right, key, value);
    else
        strcpy(root->value, value);

    updateCount(root);
    return root;
}

TreeNode *findMin(TreeNode *node)
{
    while (node->left != NULL)
        node = node->left;
    return node;
}

TreeNode *deleteNode(TreeNode *root, int key)
{
    if (root == NULL)
        return NULL;

    if (key < root->key)
    {
        root->left = deleteNode(root->left, key);
    }
    else if (key > root->key)
    {
        root->right = deleteNode(root->right, key);
    }
    else
    {
        if (root->left == NULL)
        {
            TreeNode *right_subtree = root->right;
            free(root);
            return right_subtree;
        }
        if (root->right == NULL)
        {
            TreeNode *left_subtree = root->left;
            free(root);
            return left_subtree;
        }
        TreeNode *min_node = findMin(root->right);
        root->key = min_node->key;
        strcpy(root->value, min_node->value);
        root->right = deleteNode(root->right, min_node->key);
    }

    updateCount(root);
    return root;
}

TreeNode *lookup(TreeNode *root, int key)
{
    while (root != NULL)
    {
        if (key < root->key)
            root = root->left;
        else if (key > root->key)
            root = root->right;
        else
            return root;
    }
    return NULL;
}

TreeNode *searchByRank(TreeNode *root, int rank)
{
    if (root == NULL)
        return NULL;

    int leftCount = root->left ? root->left->count : 0;

    if (rank == leftCount + 1)
        return root;
    else if (rank <= leftCount)
        return searchByRank(root->left, rank);
    else
        return searchByRank(root->right, rank - leftCount - 1);
}

void freeTree(TreeNode *root)
{
    if (root == NULL)
        return;

    freeTree(root->left);
    freeTree(root->right);
    free(root);
}

int main()
{
    TreeNode *root = NULL;
    char command[10];

    while (scanf("%s", command) == 1)
    {
        if (strcmp(command, "END") == 0)
            break;
        else if (strcmp(command, "INSERT") == 0)
        {
            int key;
            char value[10];
            scanf("%d %s", &key, value);
            root = insert(root, key, value);
        }
        else if (strcmp(command, "DELETE") == 0)
        {
            int key;
            scanf("%d", &key);
            root = deleteNode(root, key);
        }
        else if (strcmp(command, "LOOKUP") == 0)
        {
            int key;
            scanf("%d", &key);
            TreeNode *node = lookup(root, key);
            if (node)
                printf("%s\n", node->value);
        }
        else if (strcmp(command, "SEARCH") == 0)
        {
            int rank;
            scanf("%d", &rank);
            rank++;
            TreeNode *node = searchByRank(root, rank);
            if (node)
                printf("%s\n", node->value);
        }
    }

    freeTree(root);
    return 0;
}