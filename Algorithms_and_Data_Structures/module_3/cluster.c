#include <stdio.h>
#include <stdlib.h>

typedef struct
{
    long long *data;
    int size;
    int capacity;
} MinHeap;

MinHeap *createMinHeap(int capacity)
{
    MinHeap *heap = (MinHeap *)malloc(sizeof(MinHeap));
    heap->data = (long long *)malloc(capacity * sizeof(long long));
    heap->size = 0;
    heap->capacity = capacity;
    return heap;
}

void swap(long long *a, long long *b)
{
    long long aux = *a;
    *a = *b;
    *b = aux;
}

void heapifyUp(MinHeap *heap, int index)
{
    while (index != 0 && heap->data[(index - 1) / 2] > heap->data[index])
    {
        swap(&heap->data[(index - 1) / 2], &heap->data[index]);
        index = (index - 1) / 2;
    }
}

void heapifyDown(MinHeap *heap, int index)
{
    int smallest = index;
    int left = 2 * index + 1;
    int right = 2 * index + 2;

    if (left < heap->size && heap->data[left] < heap->data[smallest])
        smallest = left;
    if (right < heap->size && heap->data[right] < heap->data[smallest])
        smallest = right;
    if (smallest != index)
    {
        swap(&heap->data[smallest], &heap->data[index]);
        heapifyDown(heap, smallest);
    }
}

void insertHeap(MinHeap *heap, long long value)
{
    heap->data[heap->size] = value;
    heap->size++;
    heapifyUp(heap, heap->size - 1);
}

long long extractMin(MinHeap *heap)
{
    long long min = heap->data[0];
    heap->data[0] = heap->data[heap->size - 1];
    heap->size--;
    heapifyDown(heap, 0);
    return min;
}

void freeHeap(MinHeap *heap)
{
    free(heap->data);
    free(heap);
}

int main()
{
    int N, M;
    scanf("%d", &N);
    scanf("%d", &M);

    long long *t1 = (long long *)malloc(M * sizeof(long long));
    long long *t2 = (long long *)malloc(M * sizeof(long long));

    for (int i = 0; i < M; i++)
    {
        scanf("%lld %lld", &t1[i], &t2[i]);
    }

    MinHeap *heap = createMinHeap(N);

    for (int i = 0; i < N; i++)
    {
        insertHeap(heap, 0);
    }

    long long totalTime = 0;

    for (int i = 0; i < M; i++)
    {
        long long taskStartTime = t1[i];
        long long taskDuration = t2[i];

        long long nodeAvailableTime = extractMin(heap);

        long long startTime = (taskStartTime > nodeAvailableTime) ? taskStartTime : nodeAvailableTime;

        long long finishTime = startTime + taskDuration;

        if (finishTime > totalTime)
            totalTime = finishTime;

        insertHeap(heap, finishTime);
    }

    printf("%lld\n", totalTime);

    free(t1);
    free(t2);
    freeHeap(heap);

    return 0;
}