#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define MAXN 1000000

char str[MAXN + 1];
int n;

typedef struct Result
{
    int total_words;
    int left_letter;
    int right_letter;
} Result;

typedef struct Node
{
    int l, r;
    int total_words;
    int left_letter;
    int right_letter;
    struct Node *left, *right;
} Node;

int is_letter(char c)
{
    return c >= 'a' && c <= 'z';
}

Node *build(int l, int r)
{
    Node *node = (Node *)malloc(sizeof(Node));
    node->l = l;
    node->r = r;
    node->left = node->right = NULL;

    if (l == r)
    {
        int is_ltr = is_letter(str[l]);
        node->total_words = is_ltr;
        node->left_letter = node->right_letter = is_ltr;
    }
    else
    {
        int m = (l + r) / 2;
        node->left = build(l, m);
        node->right = build(m + 1, r);

        node->left_letter = node->left->left_letter;
        node->right_letter = node->right->right_letter;

        node->total_words = node->left->total_words + node->right->total_words;

        if (node->left->right_letter && node->right->left_letter)
        {
            node->total_words -= 1;
        }
    }

    return node;
}

void update(Node *node, int idx)
{
    if (node->l == node->r)
    {
        int is_ltr = is_letter(str[idx]);
        node->total_words = is_ltr;
        node->left_letter = node->right_letter = is_ltr;
    }
    else
    {
        if (idx <= node->left->r)
        {
            update(node->left, idx);
        }
        else
        {
            update(node->right, idx);
        }

        node->left_letter = node->left->left_letter;
        node->right_letter = node->right->right_letter;

        node->total_words = node->left->total_words + node->right->total_words;

        if (node->left->right_letter && node->right->left_letter)
        {
            node->total_words -= 1;
        }
    }
}

Result query(Node *node, int l, int r)
{
    if (node->r < l || node->l > r)
    {
        Result res = {0, -1, -1};
        return res;
    }

    if (node->l >= l && node->r <= r)
    {
        Result res = {node->total_words, node->left_letter, node->right_letter};
        return res;
    }

    Result left_res = query(node->left, l, r);
    Result right_res = query(node->right, l, r);

    Result res;
    res.total_words = left_res.total_words + right_res.total_words;

    if (left_res.right_letter != -1 && right_res.left_letter != -1 &&
    left_res.right_letter && right_res.left_letter)
    {
        res.total_words -= 1;
    }

    if (left_res.left_letter != -1)
    {
        res.left_letter = left_res.left_letter;
    }
    else
    {
        res.left_letter = right_res.left_letter;
    }

    if (right_res.right_letter != -1)
    {
        res.right_letter = right_res.right_letter;
    }
    else
    {
        res.right_letter = left_res.right_letter;
    }

    return res;
}

void delete_tree(Node *node)
{
    if (node == NULL)
        return;
    delete_tree(node->left);
    delete_tree(node->right);
    free(node);
}

int main()
{
    scanf("%s", str);
    n = strlen(str);
    Node *root = build(0, n - 1);
    char line[100], op[10];

    while (fgets(line, sizeof(line), stdin))
    {
        if (sscanf(line, "%s", op) != 1)
            continue;
        if (strcmp(op, "END") == 0)
        {
            break;
        }
        else if (strcmp(op, "COUNT") == 0)
        {
            int l, r;
            if (sscanf(line, "%*s %d %d", &l, &r) != 2)
                continue;
            Result res = query(root, l, r);
            printf("%d\n", res.total_words);
        }
        else if (strcmp(op, "UPD") == 0)
        {
            int idx;
            char c;
            if (sscanf(line, "%*s %d %c", &idx, &c) != 2)
                continue;
            str[idx] = c;
            update(root, idx);
        }
    }

    delete_tree(root);
    return 0;
}