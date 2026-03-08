#include <stdio.h>
#include <stdlib.h>

struct Elem
{
    struct Elem *prev, *next;
    int v;
};

void insertionSort(struct Elem **headRef)
{
    if (*headRef == NULL || (*headRef)->next == *headRef)
        return;

    struct Elem *sorted = NULL;
    struct Elem *current_node = *headRef;

    (*headRef)->prev->next = NULL;
    (*headRef)->prev = NULL;

    while (current_node != NULL)
    {
        struct Elem *next_node = current_node->next;

        if (sorted == NULL || current_node->v <= sorted->v)
        {
            current_node->next = sorted;
            if (sorted != NULL)
                sorted->prev = current_node;
            sorted = current_node;
            sorted->prev = NULL;
        }
        else
        {
            struct Elem *sorted_current = sorted;
            while (sorted_current->next != NULL && sorted_current->next->v < current_node->v)
            {
                sorted_current = sorted_current->next;
            }
            current_node->next = sorted_current->next;
            if (sorted_current->next != NULL)
                sorted_current->next->prev = current_node;
            sorted_current->next = current_node;
            current_node->prev = sorted_current;
        }

        current_node = next_node;
    }

    struct Elem *sorted_tail = sorted;
    while (sorted_tail->next != NULL)
        sorted_tail = sorted_tail->next;
    sorted_tail->next = sorted;
    sorted->prev = sorted_tail;

    *headRef = sorted;
}

int main()
{
    int n;
    scanf("%d", &n);

    struct Elem *head = NULL;

    for (int i = 0; i < n; i++)
    {
        int value;
        scanf("%d", &value);

        struct Elem *new_node = (struct Elem *)malloc(sizeof(struct Elem));
        new_node->v = value;

        if (head == NULL)
        {
            new_node->next = new_node;
            new_node->prev = new_node;
            head = new_node;
        }
        else
        {
            new_node->next = head;
            new_node->prev = head->prev;
            head->prev->next = new_node;
            head->prev = new_node;
        }
    }

    insertionSort(&head);

    struct Elem *current_node = head;
    for (int i = 0; i < n; i++)
    {
        printf("%d ", current_node->v);
        struct Elem *node_to_free = current_node;
        current_node = current_node->next;
        free(node_to_free);
    }
    printf("\n");

    return 0;
}