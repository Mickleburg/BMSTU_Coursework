#include <stdio.h>
#include <stdlib.h>
#include <string.h>

typedef struct Node
{
    long long key;
    long long value;
    struct Node *next;
} Node;

int main()
{
    int m;
    scanf("%d", &m);
    Node **hashTable = (Node **)malloc(m * sizeof(Node *));
    for (int i = 0; i < m; i++)
        hashTable[i] = NULL;

    char command[10];
    while (scanf("%s", command) == 1)
    {
        if (strcmp(command, "END") == 0)
            break;
        else if (strcmp(command, "ASSIGN") == 0)
        {
            long long index, value;
            scanf("%lld %lld", &index, &value);
            int hashIndex = index % m;
            if (hashIndex < 0)
                hashIndex += m;
            Node *prev = NULL;
            Node *current = hashTable[hashIndex];
            while (current != NULL && current->key != index)
            {
                prev = current;
                current = current->next;
            }
            if (current != NULL)
            {
                if (value != 0)
                    current->value = value;
                else
                {
                    if (prev == NULL)
                        hashTable[hashIndex] = current->next;
                    else
                        prev->next = current->next;
                    free(current);
                }
            }
            else
            {
                if (value != 0)
                {
                    Node *newNode = (Node *)malloc(sizeof(Node));
                    newNode->key = index;
                    newNode->value = value;
                    newNode->next = hashTable[hashIndex];
                    hashTable[hashIndex] = newNode;
                }
            }
        }
        else if (strcmp(command, "AT") == 0)
        {
            long long index;
            scanf("%lld", &index);
            int hashIndex = index % m;
            if (hashIndex < 0)
                hashIndex += m;
            Node *current = hashTable[hashIndex];
            while (current != NULL && current->key != index)
                current = current->next;
            if (current != NULL)
                printf("%lld\n", current->value);
            else
                printf("0\n");
        }
    }

    for (int i = 0; i < m; i++)
    {
        Node *current = hashTable[i];
        while (current != NULL)
        {
            Node *node_to_free = current;
            current = current->next;
            free(node_to_free);
        }
    }
    free(hashTable);
    return 0;
}