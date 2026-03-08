#include<stdio.h>

struct Elem
{
    /* «Тег», описывающий тип значения в «головe» списка */
    enum
    {
        INTEGER,
        FLOAT,
        LIST
    } tag;

    /* Само значение в «голове» списка */
    union
    {
        int i;
        float f;
        struct Elem *list;
    } value;

    /* Указатель на «хвост» списка */
    struct Elem *tail;
};

struct Elem *searchlist(struct Elem *list, int k){
    if (list == NULL){
        return NULL;
    }
    if ((list->tag == INTEGER) && (list->value.i == k)){
        return list;
    }
    return searchlist(list->tail, k);
}