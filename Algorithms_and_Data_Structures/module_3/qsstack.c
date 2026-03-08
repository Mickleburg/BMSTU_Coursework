#include <stdio.h>
#include <stdlib.h>

struct Task
{
    int low, high;
};

struct Stack
{
    struct Task *data;
    int top;
    int capacity;
};

void initStack(struct Stack *stack, int capacity)
{
    stack->data = (struct Task *)malloc(capacity * sizeof(struct Task));
    if (stack->data == NULL)
    {
        fprintf(stderr, "Ошибка выделения памяти для стека\n");
        exit(EXIT_FAILURE);
    }
    stack->top = -1;
    stack->capacity = capacity;
}

void push(struct Stack *stack, struct Task task)
{
    if (stack->top >= stack->capacity - 1)
    {
        stack->capacity *= 2;
        stack->data = (struct Task *)realloc(stack->data, stack->capacity * sizeof(struct Task));
        if (stack->data == NULL)
        {
            fprintf(stderr, "Ошибка перераспределения памяти для стека\n");
            exit(EXIT_FAILURE);
        }
    }
    stack->data[++stack->top] = task;
}

struct Task pop(struct Stack *stack)
{
    return stack->data[stack->top--];
}

int isEmpty(struct Stack *stack)
{
    return stack->top == -1;
}

void swap(int *firstElement, int *secondElement)
{
    int swap_value = *firstElement;
    *firstElement = *secondElement;
    *secondElement = swap_value;
}

void quickSort(int arr[], int n)
{
    struct Stack stack;
    initStack(&stack, n);

    struct Task initialTask = {0, n - 1};
    push(&stack, initialTask);

    while (!isEmpty(&stack))
    {
        struct Task current_task = pop(&stack);
        int low = current_task.low;
        int high = current_task.high;

        if (low < high)
        {
            int pivot = arr[high];
            int partition_index = low - 1;

            for (int j = low; j < high; j++)
            {
                if (arr[j] <= pivot)
                {
                    partition_index++;
                    swap(&arr[partition_index], &arr[j]);
                }
            }

            swap(&arr[partition_index + 1], &arr[high]);

            int pivot_index = partition_index + 1;

            if (pivot_index - 1 > low)
            {
                struct Task left_task = {low, pivot_index - 1};
                push(&stack, left_task);
            }
            if (pivot_index + 1 < high)
            {
                struct Task right_task = {pivot_index + 1, high};
                push(&stack, right_task);
            }
        }
    }
    free(stack.data);
}

int main()
{
    int n;

    scanf("%d", &n);

    int *arr = (int *)malloc(n * sizeof(int));
    if (arr == NULL)
    {
        fprintf(stderr, "Ошибка выделения памяти для массива\n");
        return EXIT_FAILURE;
    }

    for (int i = 0; i < n; i++)
    {
        scanf("%d", &arr[i]);
    }

    quickSort(arr, n);

    for (int i = 0; i < n; i++)
    {
        printf("%d ", arr[i]);
    }
    printf("\n");

    free(arr);

    return 0;
}