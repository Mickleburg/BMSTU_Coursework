#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define INITIAL_STACK_SIZE 100

typedef struct
{
    long long *items;
    int top;
    int capacity;
} Stack;

void initStack(Stack *stack)
{
    stack->capacity = INITIAL_STACK_SIZE;
    stack->items = (long long *)malloc(stack->capacity * sizeof(long long));
    stack->top = -1;
}

void resizeStack(Stack *stack)
{
    stack->capacity *= 2;
    stack->items = (long long *)realloc(stack->items, stack->capacity * sizeof(long long));
}

void push(Stack *stack, long long value)
{
    if (stack->top + 1 >= stack->capacity)
    {
        resizeStack(stack);
    }
    stack->items[++stack->top] = value;
}

long long pop(Stack *stack)
{
    if (stack->top < 0)
    {
        fprintf(stderr, "Ошибка: стек пуст.\n");
        exit(EXIT_FAILURE);
    }
    return stack->items[stack->top--];
}

long long peek(Stack *stack)
{
    if (stack->top < 0)
    {
        fprintf(stderr, "Ошибка: стек пуст.\n");
        exit(EXIT_FAILURE);
    }
    return stack->items[stack->top];
}

void freeStack(Stack *stack)
{
    free(stack->items);
}

void cmdAdd(Stack *stack)
{
    long long operand1 = pop(stack);
    long long operand2 = pop(stack);
    long long result = operand1 + operand2;
    push(stack, result);
}

void cmdSub(Stack *stack)
{
    long long operandA = pop(stack);
    long long operandB = pop(stack);
    long long result = operandA - operandB;
    push(stack, result);
}

void cmdMul(Stack *stack)
{
    long long operand1 = pop(stack);
    long long operand2 = pop(stack);
    long long result = operand1 * operand2;
    push(stack, result);
}

void cmdDiv(Stack *stack)
{
    long long operandA = pop(stack);
    long long operandB = pop(stack);
    if (operandB == 0)
    {
        fprintf(stderr, "Ошибка: деление на ноль.\n");
        exit(EXIT_FAILURE);
    }
    long long result = operandA / operandB;
    push(stack, result);
}

void cmdMax(Stack *stack)
{
    long long operand1 = pop(stack);
    long long operand2 = pop(stack);
    long long maximum = (operand1 > operand2) ? operand1 : operand2;
    push(stack, maximum);
}

void cmdMin(Stack *stack)
{
    long long operand1 = pop(stack);
    long long operand2 = pop(stack);
    long long minimum = (operand1 < operand2) ? operand1 : operand2;
    push(stack, minimum);
}

void cmdNeg(Stack *stack)
{
    long long operand = pop(stack);
    long long result = -operand;
    push(stack, result);
}

void cmdDup(Stack *stack)
{
    long long operand = peek(stack);
    push(stack, operand);
}

void cmdSwap(Stack *stack)
{
    long long operand1 = pop(stack);
    long long operand2 = pop(stack);
    push(stack, operand1);
    push(stack, operand2);
}

int main()
{
    Stack stack;
    initStack(&stack);

    char line[256];
    while (fgets(line, sizeof(line), stdin) != NULL)
    {
        // Удаляем символ перевода строки, если он есть
        line[strcspn(line, "\n")] = 0;

        if (strcmp(line, "END") == 0)
        {
            if (stack.top != 0)
            {
                fprintf(stderr, "Ошибка: после выполнения команд в стеке должно остаться одно число.\n");
                freeStack(&stack);
                exit(EXIT_FAILURE);
            }
            long long result = pop(&stack);
            printf("%lld\n", result);
            break;
        }

        char *token = strtok(line, " ");
        if (token == NULL)
        {
            fprintf(stderr, "Ошибка: пустая строка.\n");
            freeStack(&stack);
            exit(EXIT_FAILURE);
        }

        if (strcmp(token, "CONST") == 0)
        {
            char *arg = strtok(NULL, " ");
            if (arg == NULL)
            {
                fprintf(stderr, "Ошибка: команда CONST требует аргумент.\n");
                freeStack(&stack);
                exit(EXIT_FAILURE);
            }
            long long x = atoll(arg);
            push(&stack, x);
        }
        else if (strcmp(token, "ADD") == 0)
        {
            cmdAdd(&stack);
        }
        else if (strcmp(token, "SUB") == 0)
        {
            cmdSub(&stack);
        }
        else if (strcmp(token, "MUL") == 0)
        {
            cmdMul(&stack);
        }
        else if (strcmp(token, "DIV") == 0)
        {
            cmdDiv(&stack);
        }
        else if (strcmp(token, "MAX") == 0)
        {
            cmdMax(&stack);
        }
        else if (strcmp(token, "MIN") == 0)
        {
            cmdMin(&stack);
        }
        else if (strcmp(token, "NEG") == 0)
        {
            cmdNeg(&stack);
        }
        else if (strcmp(token, "DUP") == 0)
        {
            cmdDup(&stack);
        }
        else if (strcmp(token, "SWAP") == 0)
        {
            cmdSwap(&stack);
        }
        else
        {
            fprintf(stderr, "Ошибка: неизвестная команда '%s'.\n", token);
            freeStack(&stack);
            exit(EXIT_FAILURE);
        }
    }

    freeStack(&stack);
    return 0;
}