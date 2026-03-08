#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>


extern void shellsort(unsigned long nel,
		int (*compare)(unsigned long i, unsigned long j),
		void (*swap)(unsigned long i, unsigned long j));


#define MSGF(msg, ...) \
	printf("%s:%d: %s(): " msg "\n", __FILE__, __LINE__, __func__, __VA_ARGS__)


static unsigned long nel;
static int *array, *backup;


static void dump_arrays(void)
{
	printf("Source order of items:\n");
	for (unsigned long i = 0; i < nel; ++i) {
		printf("\tarray[%lu] = %d\n", i, backup[i]);
	}

	printf("Current order of items:\n");
	for (unsigned long i = 0; i < nel; ++i) {
		printf("\tarray[%lu] = %d\n", i, array[i]);
	}
}


#define CHECK_INDICES(i, j) \
	if (nel == 0) { \
		printf("%s:%d: you try to %s elements of empty array\n", \
				__FILE__, __LINE__, __func__); \
		exit(EXIT_FAILURE); \
	} else if ((i) >= nel || (j) >= nel) { \
		printf("%s:%d: %s(%lu, %lu): indices out of range (nel == %lu)\n", \
				__FILE__, __LINE__, __func__, (i), (j), nel); \
		dump_arrays(); \
		exit(EXIT_FAILURE); \
	}


static int compare(unsigned long i, unsigned long j)
{
	CHECK_INDICES(i, j);
	return
		array[i] < array[j] ? -1 :
		array[i] > array[j] ? +1 : 0;
}


static void swap(unsigned long i, unsigned long j)
{
	CHECK_INDICES(i, j);
	int old_i = array[i];
	array[i] = array[j];
	array[j] = old_i;
}


#define rand_sign() (rand() < RAND_MAX / 2 ? -1 : +1)


static int random_test(int maxval)
{
	int failed = 0;

	// prepare
	nel = 1 + rand() % 10;
	printf("Sorting of random array (item keys is %d..%d), size %lu\n",
			-maxval, maxval, nel);
	int loc_array[nel], loc_backup[nel];
	array = loc_array;
	backup = loc_backup;

	for (unsigned long i = 0; i < nel; ++i) {
		array[i] = rand_sign() * (rand() % maxval);
	}

	memcpy(backup, array, sizeof(int) * nel);


	// call
	shellsort(nel, compare, swap);


	// check
	for (unsigned long i = 0; i < nel - 1; ++i) {
		if (array[i] > array[i + 1]) {
			MSGF("array[%lu] (%d) > array[%lu] (%d)\n",
					i, array[i], i + 1, array[i + 1]);
			failed = 1;
		}
	}

	if (failed) dump_arrays();

	printf("\ttest %s\n", failed ? "failed" : "passed");
	return failed;
}


static int equal_test(void)
{
	int failed = 0;

	// prepare
	nel = 1000 + rand() % 500;
	printf("Sorting of equal array, size %lu\n", nel);
	int loc_array[nel], loc_backup[nel];
	array = loc_array;
	backup = loc_backup;

	for (unsigned long i = 0; i < nel; ++i) array[i] = 1;

	memcpy(backup, array, sizeof(int) * nel);


	// call
	shellsort(nel, compare, swap);


	// check - do nothing, test checks indices overflow in compare() and swap()
}


static void one_test(void)
{
	// prepare
	printf("Sorting of array with one item\n");
	int loc_array[1] = { 1 };
	array = loc_array;
	backup = loc_array;
	nel = 1;


	// call
	shellsort(nel, compare, swap);


	// check - do nothing, test checks indices overflow in compare() and swap()
}


static void empty_test(void)
{
	// prepare
	nel = 0;
	array = NULL;
	backup = NULL;

	// call
	shellsort(nel, compare, swap);

	// check - do nothing, test checks indices overflow in compare() and swap()
}


int main()
{
	int failed = 0;

	srand(time(NULL));

	failed += random_test(1000000);
	failed += random_test(10);

	equal_test();
	one_test();
	empty_test();

	return failed == 0 ? EXIT_SUCCESS : EXIT_FAILURE;
}

/* vim: set sw=0 ts=4 noet: */

void Shellsort_fib(unsigned long nel,
				   int (*compare)(unsigned long i, unsigned long j),
				   void (*swap)(unsigned long i, unsigned long j),
				   long fib1, long fib2)
{
	long d = fib2;
	for (long i_start = d; i_start < nel; i_start++)
	{
		long i = i_start;
		while (i >= d && (compare(i - d, i) > 0))
		{
			swap(i - d, i);
			i -= d;
		}
	}

	long temp = fib2;
	fib2 = fib1;
	fib1 = temp - fib1;

	if (fib1 > 0)
	{
		Shellsort_fib(nel, compare, swap, fib1, fib2);
	}
}

void shellsort(unsigned long nel,
			   int (*compare)(unsigned long i, unsigned long j),
			   void (*swap)(unsigned long i, unsigned long j))
{
	if (nel > 1)
	{
		long fib1 = 1, fib2 = 1, temp;
		while (fib1 + fib2 < nel)
		{
			temp = fib2;
			fib2 += fib1;
			fib1 = temp;
		}
		Shellsort_fib(nel, compare, swap, fib1, fib2);
	}
}
