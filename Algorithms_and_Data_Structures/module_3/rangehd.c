#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>

typedef struct Node
{
    char character;
    unsigned int bitmask;
    int size;
    int priority;
    struct Node *left, *right;
} Node;

Node *create_node(char ch)
{
    Node *node = (Node *)malloc(sizeof(Node));
    node->character = ch;
    node->bitmask = 1 << (ch - 'a');
    node->size = 1;
    node->priority = rand();
    node->left = node->right = NULL;
    return node;
}

void update_node(Node *node)
{
    if (!node)
        return;
    node->size = 1;
    node->bitmask = 1 << (node->character - 'a');
    if (node->left)
    {
        node->size += node->left->size;
        node->bitmask ^= node->left->bitmask;
    }
    if (node->right)
    {
        node->size += node->right->size;
        node->bitmask ^= node->right->bitmask;
    }
}

void split_treap(Node *root, int key, Node **left, Node **right)
{
    if (!root)
    {
        *left = *right = NULL;
        return;
    }
    int current_key = (root->left ? root->left->size : 0);
    if (key <= current_key)
    {
        split_treap(root->left, key, left, &(root->left));
        *right = root;
    }
    else
    {
        split_treap(root->right, key - current_key - 1, &(root->right), right);
        *left = root;
    }
    update_node(root);
}

Node *merge_treap(Node *left, Node *right)
{
    if (!left || !right)
        return left ? left : right;
    if (left->priority > right->priority)
    {
        left->right = merge_treap(left->right, right);
        update_node(left);
        return left;
    }
    else
    {
        right->left = merge_treap(left, right->left);
        update_node(right);
        return right;
    }
}

Node *build_treap(char *str, int l, int r)
{
    if (l > r)
        return NULL;
    int mid = l + (r - l) / 2;
    Node *node = create_node(str[mid]);
    node->left = build_treap(str, l, mid - 1);
    node->right = build_treap(str, mid + 1, r);
    update_node(node);
    return node;
}

int count_set_bits(unsigned int x)
{
    int cnt = 0;
    while (x)
    {
        x &= (x - 1);
        cnt++;
    }
    return cnt;
}

int is_hyperdrome(Node **root_ptr, int l, int r)
{
    Node *left_part = NULL;
    Node *mid_part = NULL;
    Node *right_part = NULL;

    split_treap(*root_ptr, r + 1, &left_part, &right_part);

    split_treap(left_part, l, &left_part, &mid_part);

    unsigned int bitmask = (mid_part ? mid_part->bitmask : 0);
    int length = r - l + 1;
    int odd_count = count_set_bits(bitmask);

    int result = 0;
    if (length % 2 == 0)
    {
        result = (odd_count == 0);
    }
    else
    {
        result = (odd_count == 1);
    }

    printf(result ? "YES\n" : "NO\n");

    left_part = merge_treap(left_part, mid_part);
    *root_ptr = merge_treap(left_part, right_part);
    return result;
}

void free_treap_memory(Node *root)
{
    if (!root)
        return;
    free_treap_memory(root->left);
    free_treap_memory(root->right);
    free(root);
}

Node *replace_substring(Node *root, int i, char *s)
{
    int len_s = strlen(s);
    Node *left = NULL;
    Node *mid = NULL;
    Node *right = NULL;

    split_treap(root, i, &left, &right);

    split_treap(right, len_s, &mid, &right);

    free_treap_memory(mid);

    Node *new_subtree = NULL;
    for (int idx = 0; s[idx] != '\0'; idx++)
    {
        Node *new_node_ptr = create_node(s[idx]);
        new_subtree = merge_treap(new_subtree, new_node_ptr);
    }

    Node *merged_left = merge_treap(left, new_subtree);
    Node *new_root = merge_treap(merged_left, right);
    return new_root;
}

int main()
{
    srand(time(NULL));

    char input_str[1000001];
    if (scanf("%s", input_str) != 1)
    {
        return 0;
    }
    int n = strlen(input_str);
    Node *root = build_treap(input_str, 0, n - 1);

    char command[10];
    while (scanf("%s", command) == 1)
    {
        if (strcmp(command, "END") == 0)
            break;
        else if (strcmp(command, "HD") == 0)
        {
            int l, r;
            if (scanf("%d %d", &l, &r) != 2)
            {
                break;
            }
            if (l < 0 || r < l || (root && r >= root->size))
            {
                printf("NO\n");
                continue;
            }
            is_hyperdrome(&root, l, r);
        }
        else if (strcmp(command, "UPD") == 0)
        {
            int i;
            char s[1000001];
            if (scanf("%d %s", &i, s) != 2)
            {
                break;
            }
            if (i < 0 || (root && i > root->size))
            {
                continue;
            }
            root = replace_substring(root, i, s);
        }
    }

    free_treap_memory(root);

    return 0;
}