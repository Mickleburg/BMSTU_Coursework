#include <stdio.h>
#include <stdlib.h>

typedef struct Node
{
    int data;
    struct Node *prev;
    struct Node *next;
} Node;

Node *create_node(int data)
{
    Node *node = (Node *)malloc(sizeof(Node));
    if (!node)
    {
        fprintf(stderr, "Ошибка памяти\n");
        exit(EXIT_FAILURE);
    }
    node->data = data;
    node->prev = node->next = NULL;
    return node;
}

int compare_abs(int a, int b)
{
    int abs_a = (a >= 0) ? a : -a;
    int abs_b = (b >= 0) ? b : -b;
    if (abs_a < abs_b)
        return -1;
    if (abs_a > abs_b)
        return 1;
    return 0;
}

Node *find_tail(Node *head)
{
    if (head == NULL)
        return NULL;
    Node *tail = head;
    while (tail->next != NULL)
        tail = tail->next;
    return tail;
}

Node *quicksort(Node *head, int (*compare)(int, int))
{
    if (head == NULL || head->next == NULL)
        return head;

    Node *pivot = head;

    Node *less_head = NULL, *less_tail = NULL;
    Node *equal_head = NULL, *equal_tail = NULL;
    Node *greater_head = NULL, *greater_tail = NULL;

    Node *current = head;
    while (current != NULL)
    {
        Node *next_node = current->next;

        current->prev = current->next = NULL;

        int cmp = compare(current->data, pivot->data);
        if (cmp < 0)
        {
            if (less_head == NULL)
            {
                less_head = less_tail = current;
            }
            else
            {
                less_tail->next = current;
                current->prev = less_tail;
                less_tail = current;
            }
        }
        else if (cmp == 0)
        {
            if (equal_head == NULL)
            {
                equal_head = equal_tail = current;
            }
            else
            {
                equal_tail->next = current;
                current->prev = equal_tail;
                equal_tail = current;
            }
        }
        else
        {
            if (greater_head == NULL)
            {
                greater_head = greater_tail = current;
            }
            else
            {
                greater_tail->next = current;
                current->prev = greater_tail;
                greater_tail = current;
            }
        }

        current = next_node;
    }

    less_head = quicksort(less_head, compare);
    greater_head = quicksort(greater_head, compare);

    less_tail = find_tail(less_head);
    greater_tail = find_tail(greater_head);

    Node *new_head = NULL;
    Node *new_tail = NULL;

    if (less_head != NULL)
    {
        new_head = less_head;
        new_tail = less_tail;
    }

    if (equal_head != NULL)
    {
        if (new_head == NULL)
        {
            new_head = equal_head;
            new_tail = equal_tail;
        }
        else
        {
            new_tail->next = equal_head;
            equal_head->prev = new_tail;
            new_tail = equal_tail;
        }
    }

    if (greater_head != NULL)
    {
        if (new_head == NULL)
        {
            new_head = greater_head;
            new_tail = greater_tail;
        }
        else
        {
            new_tail->next = greater_head;
            greater_head->prev = new_tail;
            new_tail = greater_tail;
        }
    }

    return new_head;
}

Node *make_circular_with_sentinel(Node *head)
{
    Node *sentinel = (Node *)malloc(sizeof(Node));
    if (!sentinel)
    {
        fprintf(stderr, "Проблемы с памятью\n");
        exit(EXIT_FAILURE);
    }
    sentinel->prev = sentinel->next = sentinel;

    if (head == NULL)
    {
        return sentinel;
    }

    Node *tail = head;
    while (tail->next != NULL)
    {
        tail = tail->next;
    }

    sentinel->next = head;
    head->prev = sentinel;
    tail->next = sentinel;
    sentinel->prev = tail;

    return sentinel;
}

void print_list(Node *sentinel)
{
    Node *current = sentinel->next;
    while (current != sentinel)
    {
        printf("%d ", current->data);
        current = current->next;
    }
}

void free_list(Node *sentinel)
{
    Node *current = sentinel->next;
    while (current != sentinel)
    {
        Node *temp = current;
        current = current->next;
        free(temp);
    }
    free(sentinel);
}

int main()
{
    Node *head = NULL;
    int n, value;

    if (scanf("%d", &n) != 1 || n < 0)
    {
        fprintf(stderr, "Некорректный ввод\n");
        return EXIT_FAILURE;
    }

    for (int i = 0; i < n; i++)
    {
        if (scanf("%d", &value) != 1)
        {
            fprintf(stderr, "Некорректный ввод\n");

            while (head != NULL)
            {
                Node *temp = head;
                head = head->next;
                free(temp);
            }
            return EXIT_FAILURE;
        }
        Node *new_node = create_node(value);

        if (head == NULL)
        {
            head = new_node;
        }
        else
        {
            Node *tail = head;
            while (tail->next != NULL)
            {
                tail = tail->next;
            }
            tail->next = new_node;
            new_node->prev = tail;
        }
    }

    head = quicksort(head, compare_abs);

    Node *sentinel = make_circular_with_sentinel(head);

    print_list(sentinel);

    free_list(sentinel);

    return 0;
}