#include <stdio.h>
#include <stdlib.h>
#include <string.h>

typedef struct TrieNode
{
    char *label;
    int label_len;
    int is_end;
    int count;
    int num_children;
    struct TrieNode **children;
} TrieNode;

TrieNode *create_node(char *label, int label_len)
{
    TrieNode *node = (TrieNode *)malloc(sizeof(TrieNode));
    node->label = label;
    node->label_len = label_len;
    node->is_end = 0;
    node->count = 0;
    node->num_children = 0;
    node->children = NULL;
    return node;
}

int find_child(TrieNode *node, char c)
{
    for (int i = 0; i < node->num_children; i++)
    {
        if (node->children[i]->label[0] == c)
        {
            return i;
        }
    }
    return -1;
}

void insert(TrieNode *root, const char *key)
{
    TrieNode *node = root;
    const char *str = key;
    int len = strlen(str);
    node->count++;

    while (1)
    {
        int idx = find_child(node, str[0]);
        if (idx == -1)
        {
            char *label = strdup(str);
            TrieNode *child = create_node(label, strlen(label));
            child->is_end = 1;
            child->count = 1;

            node->num_children++;
            node->children = (TrieNode **)realloc(node->children, node->num_children * sizeof(TrieNode *));
            node->children[node->num_children - 1] = child;
            return;
        }

        TrieNode *child = node->children[idx];
        int i = 0;
        while (i < child->label_len && i < len && str[i] == child->label[i])
        {
            i++;
        }

        if (i == child->label_len)
        {
            node = child;
            str += i;
            len -= i;
            node->count++;
            if (len == 0)
            {
                node->is_end = 1;
                return;
            }
            continue;
        }

        TrieNode *split_node = create_node(strndup(child->label, i), i);
        split_node->num_children = 1;
        split_node->children = (TrieNode **)malloc(sizeof(TrieNode *));
        child->label += i;
        child->label_len -= i;
        split_node->children[0] = child;
        split_node->count = child->count;
        split_node->is_end = 0;

        node->children[idx] = split_node;
        node = split_node;

        str += i;
        len -= i;
        node->count++;
        if (len == 0)
        {
            node->is_end = 1;
            return;
        }

        TrieNode *new_child = create_node(strdup(str), len);
        new_child->is_end = 1;
        new_child->count = 1;

        node->num_children++;
        node->children = (TrieNode **)realloc(node->children, node->num_children * sizeof(TrieNode *));
        node->children[node->num_children - 1] = new_child;
        return;
    }
}

int delete(TrieNode *node, const char *key)
{
    const char *str = key;
    int len = strlen(str);

    if (len == 0)
    {
        if (node->is_end)
        {
            node->is_end = 0;
            node->count--;
            return 1;
        }
        return 0;
    }

    int idx = find_child(node, str[0]);
    if (idx == -1)
    {
        return 0;
    }

    TrieNode *child = node->children[idx];
    int i = 0;
    while (i < child->label_len && i < len && str[i] == child->label[i])
    {
        i++;
    }

    if (i < child->label_len)
    {
        return 0;
    }

    int deleted = delete (child, str + i);
    if (deleted)
    {
        node->count--;
        if (child->count == 0)
        {
            free(child->label);
            free(child->children);
            free(child);
            for (int j = idx; j < node->num_children - 1; j++)
            {
                node->children[j] = node->children[j + 1];
            }
            node->num_children--;
            node->children = (TrieNode **)realloc(node->children, node->num_children * sizeof(TrieNode *));
        }
        return 1;
    }
    return 0;
}

int search_prefix(TrieNode *node, const char *prefix)
{
    const char *str = prefix;
    int len = strlen(str);

    if (len == 0)
    {
        return node->count;
    }

    int idx = find_child(node, str[0]);
    if (idx == -1)
    {
        return 0;
    }

    TrieNode *child = node->children[idx];
    int i = 0;
    while (i < child->label_len && i < len && str[i] == child->label[i])
    {
        i++;
    }

    if (i == len)
    {
        if (i <= child->label_len)
        {
            return child->count;
        }
    }

    if (i == child->label_len)
    {
        return search_prefix(child, str + i);
    }

    return 0;
}

void free_trie(TrieNode *node)
{
    for (int i = 0; i < node->num_children; i++)
    {
        free_trie(node->children[i]);
    }
    free(node->label);
    free(node->children);
    free(node);
}

int main()
{
    TrieNode *root = create_node(NULL, 0);
    char command[100];
    while (scanf("%s", command) != EOF)
    {
        if (strcmp(command, "END") == 0)
        {
            break;
        }
        if (strcmp(command, "INSERT") == 0)
        {
            char word[100001];
            scanf("%s", word);
            insert(root, word);
        }
        else if (strcmp(command, "DELETE") == 0)
        {
            char word[100001];
            scanf("%s", word);
            delete (root, word);
        }
        else if (strcmp(command, "PREFIX") == 0)
        {
            char prefix[100001];
            scanf("%s", prefix);
            int count = search_prefix(root, prefix);
            printf("%d\n", count);
        }
    }
    free_trie(root);
    return 0;
}