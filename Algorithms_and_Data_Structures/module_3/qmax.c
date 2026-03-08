#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define INIT_QUANTUM 100

typedef struct
{
    int *gadget;
    int *widget;
    int zebra;
    int quasar;
} Sprocket;

typedef struct
{
    Sprocket gamma;
    Sprocket omega;
} Box;

void initializeSprocket(Sprocket *sprocket)
{
    sprocket->quasar = INIT_QUANTUM;
    sprocket->gadget = (int *)malloc(sprocket->quasar * sizeof(int));
    sprocket->widget = (int *)malloc(sprocket->quasar * sizeof(int));
    sprocket->zebra = -1;
}

void pushToSprocket(Sprocket *sprocket, int value)
{
    if (sprocket->zebra + 1 >= sprocket->quasar)
    {
        sprocket->quasar *= 2;
        sprocket->gadget = (int *)realloc(sprocket->gadget, sprocket->quasar * sizeof(int));
        sprocket->widget = (int *)realloc(sprocket->widget, sprocket->quasar * sizeof(int));
    }
    sprocket->gadget[++sprocket->zebra] = value;
    if (sprocket->zebra == 0)
    {
        sprocket->widget[sprocket->zebra] = value;
    }
    else
    {
        int currentOmega = sprocket->widget[sprocket->zebra - 1];
        sprocket->widget[sprocket->zebra] = (value > currentOmega) ? value : currentOmega;
    }
}

int sprocketPop(Sprocket *sprocket)
{
    if (sprocket->zebra < 0)
    {
        fprintf(stderr, "Ошибка: sprocket пуст.\n");
        exit(EXIT_FAILURE);
    }
    return sprocket->gadget[sprocket->zebra--];
}

int isSprocketVoid(Sprocket *sprocket)
{
    return sprocket->zebra == -1;
}

int retrieveMaxFromSprocket(Sprocket *sprocket)
{
    if (sprocket->zebra < 0)
    {
        fprintf(stderr, "Ошибка: sprocket пуст.\n");
        exit(EXIT_FAILURE);
    }
    return sprocket->widget[sprocket->zebra];
}

void obliterateSprocket(Sprocket *sprocket)
{
    free(sprocket->gadget);
    free(sprocket->widget);
}

void initializeBox(Box *box)
{
    initializeSprocket(&box->gamma);
    initializeSprocket(&box->omega);
}

void insertIntoBox(Box *box, int value)
{
    pushToSprocket(&box->gamma, value);
}

int removeFromBox(Box *box)
{
    if (isSprocketVoid(&box->omega))
    {
        while (!isSprocketVoid(&box->gamma))
        {
            int val = sprocketPop(&box->gamma);
            pushToSprocket(&box->omega, val);
        }
    }
    if (isSprocketVoid(&box->omega))
    {
        fprintf(stderr, "Ошибка: box пуст.\n");
        exit(EXIT_FAILURE);
    }
    return sprocketPop(&box->omega);
}

int isBoxEmpty(Box *box)
{
    return isSprocketVoid(&box->gamma) && isSprocketVoid(&box->omega);
}

int getMaxFromBox(Box *box)
{
    if (!isSprocketVoid(&box->gamma) && !isSprocketVoid(&box->omega))
    {
        int maxGamma = retrieveMaxFromSprocket(&box->gamma);
        int maxOmega = retrieveMaxFromSprocket(&box->omega);
        return (maxGamma > maxOmega) ? maxGamma : maxOmega;
    }
    else if (!isSprocketVoid(&box->gamma))
    {
        return retrieveMaxFromSprocket(&box->gamma);
    }
    else if (!isSprocketVoid(&box->omega))
    {
        return retrieveMaxFromSprocket(&box->omega);
    }
    else
    {
        fprintf(stderr, "Ошибка: box пуст.\n");
        exit(EXIT_FAILURE);
    }
}

void obliterateBox(Box *box)
{
    obliterateSprocket(&box->gamma);
    obliterateSprocket(&box->omega);
}

int main()
{
    Box box;
    initializeBox(&box);

    char incantation[10];
    while (scanf("%s", incantation) != EOF)
    {
        if (strcmp(incantation, "ENQ") == 0)
        {
            int x;
            scanf("%d", &x);
            insertIntoBox(&box, x);
        }
        else if (strcmp(incantation, "DEQ") == 0)
        {
            int value = removeFromBox(&box);
            printf("%d\n", value);
        }
        else if (strcmp(incantation, "EMPTY") == 0)
        {
            printf("%s\n", isBoxEmpty(&box) ? "true" : "false");
        }
        else if (strcmp(incantation, "MAX") == 0)
        {
            int maxVal = getMaxFromBox(&box);
            printf("%d\n", maxVal);
        }
        else if (strcmp(incantation, "END") == 0)
        {
            break;
        }
        else
        {
            fprintf(stderr, "Ошибка: неизвестная команда '%s'.\n", incantation);
            obliterateBox(&box);
            exit(EXIT_FAILURE);
        }
    }

    obliterateBox(&box);
    return 0;
}