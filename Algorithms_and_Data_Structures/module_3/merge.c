#include <stdio.h>
#include <stdlib.h>

typedef struct
{
    int *array;
    int index;
    int size;
} ArrayState;

typedef struct
{
    ArrayState **data;
    int size;
} MinHeap;

void swap(ArrayState **a, ArrayState **b)
{
    ArrayState *swap_node = *a;
    *a = *b;
    *b = swap_node;
}

void heapify(MinHeap *heap, int i)
{
    int smallest = i;
    int left_child = 2 * i + 1;
    int right_child = 2 * i + 2;

    if (left_child < heap->size && heap->data[left_child]->array[heap->data[left_child]->index] <
                                       heap->data[smallest]->array[heap->data[smallest]->index])
    {
        smallest = left_child;
    }

    if (right_child < heap->size && heap->data[right_child]->array[heap->data[right_child]->index] <
                                        heap->data[smallest]->array[heap->data[smallest]->index])
    {
        smallest = right_child;
    }

    if (smallest != i)
    {
        swap(&heap->data[i], &heap->data[smallest]);
        heapify(heap, smallest);
    }
}

void buildHeap(MinHeap *heap)
{
    for (int i = heap->size / 2 - 1; i >= 0; i--)
    {
        heapify(heap, i);
    }
}

ArrayState *extractMin(MinHeap *heap)
{
    if (heap->size == 0)
    {
        return NULL;
    }
    ArrayState *min_node = heap->data[0];
    heap->data[0] = heap->data[heap->size - 1];
    heap->size--;
    heapify(heap, 0);
    return min_node;
}

void insertHeap(MinHeap *heap, ArrayState *element)
{
    heap->size++;
    int i = heap->size - 1;
    heap->data[i] = element;

    while (i != 0 && heap->data[(i - 1) / 2]->array[heap->data[(i - 1) / 2]->index] >
                         heap->data[i]->array[heap->data[i]->index])
    {
        swap(&heap->data[i], &heap->data[(i - 1) / 2]);
        i = (i - 1) / 2;
    }
}

int main()
{
    int k;
    scanf("%d", &k);

    int *sizes = (int *)malloc(k * sizeof(int));
    int totalSize = 0;

    for (int i = 0; i < k; i++)
    {
        scanf("%d", &sizes[i]);
        totalSize += sizes[i];
    }

    ArrayState **arrays = (ArrayState **)malloc(k * sizeof(ArrayState *));
    for (int i = 0; i < k; i++)
    {
        arrays[i] = (ArrayState *)malloc(sizeof(ArrayState));
        arrays[i]->size = sizes[i];
        arrays[i]->index = 0;
        arrays[i]->array = (int *)malloc(sizes[i] * sizeof(int));

        for (int j = 0; j < sizes[i]; j++)
        {
            scanf("%d", &arrays[i]->array[j]);
        }
    }

    MinHeap heap;
    heap.size = 0;
    heap.data = (ArrayState **)malloc(k * sizeof(ArrayState *));

    for (int i = 0; i < k; i++)
    {
        if (arrays[i]->size > 0)
        {
            heap.data[heap.size] = arrays[i];
            heap.size++;
        }
    }

    buildHeap(&heap);

    int *result = (int *)malloc(totalSize * sizeof(int));
    int count = 0;

    while (heap.size > 0)
    {
        ArrayState *current_min = extractMin(&heap);
        result[count++] = current_min->array[current_min->index];
        current_min->index++;

        if (current_min->index < current_min->size)
        {
            insertHeap(&heap, current_min);
        }
    }

    for (int i = 0; i < totalSize; i++)
    {
        printf("%d ", result[i]);
    }
    printf("\n");

    for (int i = 0; i < k; i++)
    {
        free(arrays[i]->array);
        free(arrays[i]);
    }
    free(arrays);
    free(heap.data);
    free(result);
    free(sizes);

    return 0;
}