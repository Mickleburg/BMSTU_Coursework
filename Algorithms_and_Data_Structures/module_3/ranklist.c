#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>

#define MAX_LEVEL 32
#define P 0.5

typedef struct Node
{
    int key;
    char *value;
    struct Node **next;
    int *width;
} Node;

typedef struct SkipList
{
    int currentLevel;
    int count;
    Node *header;
} SkipList;

Node *createSkipNode(int level, int key, char *value)
{
    Node *node = (Node *)malloc(sizeof(Node));
    node->key = key;
    node->value = value;
    node->next = (Node **)malloc(sizeof(Node *) * (level + 1));
    node->width = (int *)malloc(sizeof(int) * (level + 1));
    return node;
}

SkipList *initializeSkipList()
{
    SkipList *list = (SkipList *)malloc(sizeof(SkipList));
    list->currentLevel = 0;
    list->count = 0;
    list->header = createSkipNode(MAX_LEVEL, 0, NULL);
    for (int i = 0; i <= MAX_LEVEL; i++)
    {
        list->header->next[i] = NULL;
        list->header->width[i] = 0;
    }
    return list;
}

int randomLevel()
{
    int lvl = 0;
    while (((double)rand() / RAND_MAX) < P && lvl < MAX_LEVEL)
    {
        lvl++;
    }
    return lvl;
}

void insertNode(SkipList *list, int key, char *value)
{
    Node *update[MAX_LEVEL + 1];
    int steps[MAX_LEVEL + 1];
    Node *x = list->header;
    int i;

    for (i = list->currentLevel; i >= 0; i--)
    {
        if (i == list->currentLevel)
        {
            steps[i] = 0;
        }
        else
        {
            steps[i] = steps[i + 1];
        }
        while (x->next[i] != NULL && x->next[i]->key < key)
        {
            steps[i] += x->width[i];
            x = x->next[i];
        }
        update[i] = x;
    }

    x = x->next[0];

    if (x != NULL && x->key == key)
    {
        free(x->value);
        x->value = value;
    }
    else
    {
        int lvl = randomLevel();
        if (lvl > list->currentLevel)
        {
            for (i = list->currentLevel + 1; i <= lvl; i++)
            {
                update[i] = list->header;
                update[i]->width[i] = list->count;
                steps[i] = 0;
            }
            list->currentLevel = lvl;
        }
        x = createSkipNode(lvl, key, value);
        for (i = 0; i <= lvl; i++)
        {
            x->next[i] = update[i]->next[i];
            update[i]->next[i] = x;

            x->width[i] = update[i]->width[i] - (steps[0] - steps[i]);
            update[i]->width[i] = (steps[0] - steps[i]) + 1;
        }

        for (i = lvl + 1; i <= list->currentLevel; i++)
        {
            update[i]->width[i]++;
        }
        list->count++;
    }
}

void deleteNode(SkipList *list, int key)
{
    Node *update[MAX_LEVEL + 1];
    int steps[MAX_LEVEL + 1];
    Node *x = list->header;
    int i;

    for (i = list->currentLevel; i >= 0; i--)
    {
        if (i == list->currentLevel)
            steps[i] = 0;
        else
            steps[i] = steps[i + 1];
        while (x->next[i] != NULL && x->next[i]->key < key)
        {
            steps[i] += x->width[i];
            x = x->next[i];
        }
        update[i] = x;
    }

    x = x->next[0];

    if (x != NULL && x->key == key)
    {
        for (i = 0; i <= list->currentLevel; i++)
        {
            if (update[i]->next[i] == x)
            {
                update[i]->width[i] += x->width[i] - 1;
                update[i]->next[i] = x->next[i];
            }
            else
            {
                update[i]->width[i]--;
            }
        }
        free(x->value);
        free(x->next);
        free(x->width);
        free(x);
        while (list->currentLevel > 0 && list->header->next[list->currentLevel] == NULL)
        {
            list->currentLevel--;
        }
        list->count--;
    }
}

char *lookupNode(SkipList *list, int key)
{
    Node *x = list->header;
    int i;
    for (i = list->currentLevel; i >= 0; i--)
    {
        while (x->next[i] && x->next[i]->key < key)
        {
            x = x->next[i];
        }
    }
    x = x->next[0];
    if (x != NULL && x->key == key)
    {
        return x->value;
    }
    return NULL;
}

int getRank(SkipList *list, int key)
{
    Node *x = list->header;
    int rank = 0;
    int i;
    for (i = list->currentLevel; i >= 0; i--)
    {
        while (x->next[i] != NULL && x->next[i]->key < key)
        {
            rank += x->width[i];
            x = x->next[i];
        }
    }
    x = x->next[0];
    if (x != NULL && x->key == key)
    {
        return rank;
    }
    else
    {
        return -1;
    }
}

void freeSkipList(SkipList *list)
{
    Node *current = list->header->next[0];
    while (current != NULL)
    {
        Node *next_node = current->next[0];
        free(current->value);
        free(current->next);
        free(current->width);
        free(current);
        current = next_node;
    }
    free(list->header->next);
    free(list->header->width);
    free(list->header);
    free(list);
}

int main()
{
    srand((unsigned int)time(NULL));
    SkipList *list = initializeSkipList();
    char operation[10];
    while (scanf("%s", operation) == 1)
    {
        if (strcmp(operation, "END") == 0)
        {
            break;
        }
        else if (strcmp(operation, "INSERT") == 0)
        {
            int key;
            char value[15];
            scanf("%d %s", &key, value);
            char *newValue = (char *)malloc(strlen(value) + 1);
            strcpy(newValue, value);
            insertNode(list, key, newValue);
        }
        else if (strcmp(operation, "DELETE") == 0)
        {
            int key;
            scanf("%d", &key);
            deleteNode(list, key);
        }
        else if (strcmp(operation, "LOOKUP") == 0)
        {
            int key;
            scanf("%d", &key);
            char *val = lookupNode(list, key);
            if (val)
            {
                printf("%s\n", val);
            }
        }
        else if (strcmp(operation, "RANK") == 0)
        {
            int key;
            scanf("%d", &key);
            int r = getRank(list, key);
            if (r != -1)
            {
                printf("%d\n", r);
            }
        }
    }
    freeSkipList(list);
    return 0;
}