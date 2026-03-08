#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>

#define CONST 0
#define SPEC 1
#define IDENT 2

typedef struct AVLNode
{
    char *key;
    int value;
    int height;
    struct AVLNode *left;
    struct AVLNode *right;
} AVLNode;

int height(AVLNode *node)
{
    return node ? node->height : 0;
}

int max(int a, int b)
{
    return a > b ? a : b;
}

AVLNode *createNode(char *key, int value)
{
    AVLNode *node = (AVLNode *)malloc(sizeof(AVLNode));
    node->key = key;
    node->value = value;
    node->left = node->right = NULL;
    node->height = 1;
    return node;
}

AVLNode *rightRotate(AVLNode *y)
{
    AVLNode *x = y->left;
    AVLNode *subtree = x->right;

    x->right = y;
    y->left = subtree;

    y->height = max(height(y->left), height(y->right)) + 1;
    x->height = max(height(x->left), height(x->right)) + 1;

    return x;
}

AVLNode *leftRotate(AVLNode *x)
{
    AVLNode *y = x->right;
    AVLNode *subtree = y->left;

    y->left = x;
    x->right = subtree;

    x->height = max(height(x->left), height(x->right)) + 1;
    y->height = max(height(y->left), height(y->right)) + 1;

    return y;
}

int getBalance(AVLNode *node)
{
    return node ? height(node->left) - height(node->right) : 0;
}

AVLNode *insert(AVLNode *node, char *key, int value)
{
    if (node == NULL)
        return createNode(key, value);

    if (strcmp(key, node->key) < 0)
        node->left = insert(node->left, key, value);
    else if (strcmp(key, node->key) > 0)
        node->right = insert(node->right, key, value);
    else
        return node;

    node->height = 1 + max(height(node->left), height(node->right));
    int balance = getBalance(node);

    if (balance > 1 && strcmp(key, node->left->key) < 0)
        return rightRotate(node);

    if (balance < -1 && strcmp(key, node->right->key) > 0)
        return leftRotate(node);

    if (balance > 1 && strcmp(key, node->left->key) > 0)
    {
        node->left = leftRotate(node->left);
        return rightRotate(node);
    }

    if (balance < -1 && strcmp(key, node->right->key) < 0)
    {
        node->right = rightRotate(node->right);
        return leftRotate(node);
    }

    return node;
}

AVLNode *find(AVLNode *node, char *key)
{
    if (node == NULL)
        return NULL;

    if (strcmp(key, node->key) == 0)
        return node;
    else if (strcmp(key, node->key) < 0)
        return find(node->left, key);
    else
        return find(node->right, key);
}

void freeAVLTree(AVLNode *node)
{
    if (node == NULL)
        return;
    freeAVLTree(node->left);
    freeAVLTree(node->right);
    free(node->key);
    free(node);
}

int main()
{
    int n;
    scanf("%d", &n);
    getchar();

    AVLNode *identifiers = NULL;
    int ident_count = 0;

    int c;
    while ((c = getchar()) != EOF)
    {
        if (c == '\n')
            break;

        if (isspace(c))
            continue;

        if (isdigit(c))
        {
            long value = c - '0';
            while ((c = getchar()) != EOF && isdigit(c))
                value = value * 10 + (c - '0');
            printf("CONST %ld\n", value);

            if (c == EOF || c == '\n')
                break;
            if (!isspace(c))
            {
                if (isalpha(c))
                {
                    fprintf(stderr, "Ошибка: отсутствует пробел между константой и идентификатором.\n");
                    return 1;
                }
                else
                    ungetc(c, stdin);
            }
        }
        else if (isalpha(c))
        {
            char buffer[256];
            int idx = 0;
            buffer[idx++] = c;
            while ((c = getchar()) != EOF && isalnum(c))
            {
                if (idx < 255)
                    buffer[idx++] = c;
            }
            buffer[idx] = '\0';

            char *key = (char *)malloc(strlen(buffer) + 1);
            strcpy(key, buffer);

            AVLNode *found = find(identifiers, key);
            int value;
            if (found == NULL)
            {
                value = ident_count++;
                identifiers = insert(identifiers, key, value);
            }
            else
            {
                value = found->value;
                free(key);
            }
            printf("IDENT %d\n", value);

            if (c == EOF || c == '\n')
                break;
            if (!isspace(c))
                ungetc(c, stdin);
        }
        else if (c == '+' || c == '-' || c == '*' || c == '/' || c == '(' || c == ')')
        {
            int value;
            switch (c)
            {
            case '+':
                value = 0;
                break;
            case '-':
                value = 1;
                break;
            case '*':
                value = 2;
                break;
            case '/':
                value = 3;
                break;
            case '(':
                value = 4;
                break;
            case ')':
                value = 5;
                break;
            default:
                value = -1;
                break;
            }
            printf("SPEC %d\n", value);
        }
        else
        {
        }
    }

    freeAVLTree(identifiers);
    return 0;
}