#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define MAX_LENGTH 1000

struct Elem
{
    struct Elem *next;
    char *word;
};

struct Elem *createElement(char *word)
{
    struct Elem *newElement = (struct Elem *)malloc(sizeof(struct Elem));
    if (!newElement)
    {
        fprintf(stderr, "Ошибка выделения памяти\n");
        exit(EXIT_FAILURE);
    }
    newElement->word = word;
    newElement->next = NULL;
    return newElement;
}

void appendElement(struct Elem **headRef, struct Elem **tailRef, struct Elem *newElement)
{
    if (*headRef == NULL)
    {
        *headRef = newElement;
        *tailRef = newElement;
    }
    else
    {
        (*tailRef)->next = newElement;
        *tailRef = newElement;
    }
}

struct Elem *bsort(struct Elem *list)
{
    if (list == NULL)
    {
        return NULL;
    }
    int swapped;
    struct Elem *ptr1;
    struct Elem *endPtr = NULL;
    do
    {
        swapped = 0;
        ptr1 = list;
        while (ptr1->next != endPtr)
        {
            if (strlen(ptr1->word) > strlen(ptr1->next->word))
            {
                char *swap_holder = ptr1->word;
                ptr1->word = ptr1->next->word;
                ptr1->next->word = swap_holder;
                swapped = 1;
            }
            ptr1 = ptr1->next;
        }
        endPtr = ptr1;
    } while (swapped);
    return list;
}

struct Elem *parseInput(char *input)
{
    struct Elem *head = NULL;
    struct Elem *tail = NULL;

    int position = 0;
    while (input[position] != '\0')
    {
        while (input[position] == ' ' && input[position] != '\0')
        {
            position++;
        }
        if (input[position] == '\0')
        {
            break;
        }
        int start = position;
        while (input[position] != ' ' && input[position] != '\0')
        {
            position++;
        }
        int end = position;

        int wordLength = end - start;
        char *word = (char *)malloc((wordLength + 1) * sizeof(char));
        if (!word)
        {
            fprintf(stderr, "Ошибка выделения памяти для слова\n");
            exit(EXIT_FAILURE);
        }
        strncpy(word, &input[start], wordLength);
        word[wordLength] = '\0';

        struct Elem *newNode = createElement(word);
        appendElement(&head, &tail, newNode);
    }
    return head;
}

void freeList(struct Elem *head)
{
    while (head != NULL)
    {
        struct Elem *node_to_free = head;
        head = head->next;
        free(node_to_free->word);
        free(node_to_free);
    }
}

void printList(struct Elem *head)
{
    struct Elem *current = head;
    while (current != NULL)
    {
        printf("%s", current->word);
        if (current->next != NULL)
        {
            printf(" ");
        }
        current = current->next;
    }
    printf("\n");
}

int main()
{
    char input[MAX_LENGTH];

    if (fgets(input, MAX_LENGTH, stdin) == NULL)
    {
        fprintf(stderr, "Ошибка чтения ввода.\n");
        return EXIT_FAILURE;
    }

    size_t len = strlen(input);
    if (len > 0 && input[len - 1] == '\n')
    {
        input[len - 1] = '\0';
    }

    struct Elem *wordList = parseInput(input);

    wordList = bsort(wordList);

    printList(wordList);

    freeList(wordList);

    return 0;
}