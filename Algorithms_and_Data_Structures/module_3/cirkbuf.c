#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define INITIAL_CAPACITY 4

typedef struct
{
    int *data;
    int head;
    int tail;
    int capacity;
    int count;
} Queue;

void InitQueue(Queue *q)
{
    q->capacity = INITIAL_CAPACITY;
    q->data = (int *)malloc(q->capacity * sizeof(int));
    q->head = 0;
    q->tail = 0;
    q->count = 0;
}

int QueueEmpty(Queue *q)
{
    return q->count == 0;
}

void Resize(Queue *q)
{
    int new_capacity = q->capacity * 2;
    int *new_data = (int *)malloc(new_capacity * sizeof(int));
    if (q->head < q->tail)
    {
        memcpy(new_data, q->data + q->head, q->count * sizeof(int));
    }
    else
    {
        int first_part_size = q->capacity - q->head;
        memcpy(new_data, q->data + q->head, first_part_size * sizeof(int));
        memcpy(new_data + first_part_size, q->data, q->tail * sizeof(int));
    }
    free(q->data);
    q->data = new_data;
    q->capacity = new_capacity;
    q->head = 0;
    q->tail = q->count;
}


void Enqueue(Queue *q, int value)
{
    if (q->count == q->capacity)
    {
        Resize(q);
    }
    q->data[q->tail] = value;
    q->tail = (q->tail + 1) % q->capacity;
    q->count++;
}


int Dequeue(Queue *q)
{
    if (QueueEmpty(q))
    {
        fprintf(stderr, "Ошибка: очередь пуста\n");
        exit(EXIT_FAILURE);
    }
    int value = q->data[q->head];
    q->head = (q->head + 1) % q->capacity;
    q->count--;
    return value;
}


void FreeQueue(Queue *q)
{
    free(q->data);
}


int main()
{
    Queue queue;
    InitQueue(&queue);

    char command[10];
    while (scanf("%s", command) != EOF)
    {
        if (strcmp(command, "ENQ") == 0)
        {
            int x;
            scanf("%d", &x);
            Enqueue(&queue, x);
        }
        else if (strcmp(command, "DEQ") == 0)
        {
            int value = Dequeue(&queue);
            printf("%d\n", value);
        }
        else if (strcmp(command, "EMPTY") == 0)
        {
            printf("%s\n", QueueEmpty(&queue) ? "true" : "false");
        }
        else if (strcmp(command, "END") == 0)
        {
            break;
        }
        else
        {
            fprintf(stderr, "Ошибка: неизвестная команда '%s'\n", command);
            FreeQueue(&queue);
            exit(EXIT_FAILURE);
        }
    }

    FreeQueue(&queue);
    return 0;
}