#include <math.h>
#include <mpi.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

typedef struct {
    int n;
    double eps;
    int max_iter;
    int random_solution;
} Options;

static void usage(const char *name) {
    printf("Usage: %s [--n N] [--eps EPS] [--max-iter K] [--task known|random]\n", name);
}

static int parse_options(int argc, char **argv, Options *opt) {
    *opt = (Options){1000, 1e-5, 100000, 0};
    for (int i = 1; i < argc; ++i) {
        if (!strcmp(argv[i], "--n") && i + 1 < argc) opt->n = atoi(argv[++i]);
        else if (!strcmp(argv[i], "--eps") && i + 1 < argc) opt->eps = atof(argv[++i]);
        else if (!strcmp(argv[i], "--max-iter") && i + 1 < argc) opt->max_iter = atoi(argv[++i]);
        else if (!strcmp(argv[i], "--task") && i + 1 < argc) {
            const char *task = argv[++i];
            if (!strcmp(task, "known")) opt->random_solution = 0;
            else if (!strcmp(task, "random")) opt->random_solution = 1;
            else return 0;
        } else return 0;
    }
    return opt->n > 0 && isfinite(opt->eps) && opt->eps > 0.0 && opt->max_iter > 0;
}

static void make_layout(int n, int processes, int *counts, int *offsets) {
    int base = n / processes;
    int extra = n % processes;
    int offset = 0;
    for (int p = 0; p < processes; ++p) {
        counts[p] = base + (p < extra);
        offsets[p] = offset;
        offset += counts[p];
    }
}

static void fill_local_matrix(double *a, int local_rows, int start_row, int n) {
    for (int i = 0; i < local_rows; ++i)
        for (int j = 0; j < n; ++j)
            a[(size_t)i * n + j] = start_row + i == j ? 2.0 : 1.0;
}

static void multiply_local(const double *a, const double *x, double *result,
                           int local_rows, int n) {
    for (int i = 0; i < local_rows; ++i) {
        double sum = 0.0;
        for (int j = 0; j < n; ++j) sum += a[(size_t)i * n + j] * x[j];
        result[i] = sum;
    }
}

static double global_dot(const double *a, const double *b, int local_rows) {
    double local_sum = 0.0;
    double sum;
    for (int i = 0; i < local_rows; ++i) local_sum += a[i] * b[i];
    MPI_Allreduce(&local_sum, &sum, 1, MPI_DOUBLE, MPI_SUM, MPI_COMM_WORLD);
    return sum;
}

int main(int argc, char **argv) {
    MPI_Init(&argc, &argv);

    int rank, processes;
    MPI_Comm_rank(MPI_COMM_WORLD, &rank);
    MPI_Comm_size(MPI_COMM_WORLD, &processes);

    Options opt;
    if (!parse_options(argc, argv, &opt)) {
        if (rank == 0) usage(argv[0]);
        MPI_Finalize();
        return 1;
    }
    if (processes > opt.n) {
        if (rank == 0) fprintf(stderr, "The number of processes must not exceed N.\n");
        MPI_Finalize();
        return 1;
    }

    int *counts = malloc((size_t)processes * sizeof(*counts));
    int *offsets = malloc((size_t)processes * sizeof(*offsets));
    if (!counts || !offsets) MPI_Abort(MPI_COMM_WORLD, 1);
    make_layout(opt.n, processes, counts, offsets);

    int n = opt.n;
    int local_rows = counts[rank];
    int start_row = offsets[rank];
    double *a = malloc((size_t)local_rows * n * sizeof(*a));
    double *b = malloc((size_t)n * sizeof(*b));
    double *x = calloc((size_t)n, sizeof(*x));
    double *answer = malloc((size_t)n * sizeof(*answer));
    double *new_x = malloc((size_t)local_rows * sizeof(*new_x));
    double *residual = malloc((size_t)local_rows * sizeof(*residual));
    if (!a || !b || !x || !answer || !new_x || !residual) MPI_Abort(MPI_COMM_WORLD, 1);

    fill_local_matrix(a, local_rows, start_row, n);
    for (int i = 0; i < n; ++i)
        answer[i] = opt.random_solution ? sin(2.0 * acos(-1.0) * i / n) : 1.0;
    for (int i = 0; i < n; ++i) {
        b[i] = 0.0;
        for (int j = 0; j < n; ++j)
            b[i] += (i == j ? 2.0 : 1.0) * answer[j];
    }

    double local_b2 = 0.0;
    for (int i = 0; i < local_rows; ++i)
        local_b2 += b[start_row + i] * b[start_row + i];
    double b2;
    MPI_Allreduce(&local_b2, &b2, 1, MPI_DOUBLE, MPI_SUM, MPI_COMM_WORLD);
    double norm_b = sqrt(b2);
    if (norm_b == 0.0) norm_b = 1.0;

    double tau = 0.1 / n;
    double relative_residual = 0.0;
    int iterations = 0;
    int converged = 0;
    MPI_Barrier(MPI_COMM_WORLD);
    double started = MPI_Wtime();

    for (;;) {
        // Each process computes the residual for its own consecutive rows.
        multiply_local(a, x, residual, local_rows, n);
        for (int i = 0; i < local_rows; ++i) residual[i] -= b[start_row + i];

        relative_residual = sqrt(global_dot(residual, residual, local_rows)) / norm_b;
        if (relative_residual < opt.eps) {
            converged = 1;
            break;
        }
        if (!isfinite(relative_residual) || iterations == opt.max_iter) break;
        for (int i = 0; i < local_rows; ++i)
            new_x[i] = x[start_row + i] - tau * residual[i];
        // All processes need the complete x for the next matrix-vector product.
        MPI_Allgatherv(new_x, local_rows, MPI_DOUBLE, x, counts, offsets,
                       MPI_DOUBLE, MPI_COMM_WORLD);
        ++iterations;
    }
    double elapsed = MPI_Wtime() - started;
    double max_elapsed;
    MPI_Reduce(&elapsed, &max_elapsed, 1, MPI_DOUBLE, MPI_MAX, 0, MPI_COMM_WORLD);

    double local_difference = 0.0;
    for (int i = 0; i < local_rows; ++i) {
        double difference = fabs(x[start_row + i] - answer[start_row + i]);
        if (difference > local_difference) local_difference = difference;
    }
    double max_difference;
    MPI_Reduce(&local_difference, &max_difference, 1, MPI_DOUBLE, MPI_MAX, 0, MPI_COMM_WORLD);

    if (rank == 0) {
        printf("Implementation: MPI\nMethod: simple iteration\nMatrix size: %d\n"
               "Task: %s\nEpsilon: %.12e\nTau: %.12e\n"
               "Processes: %d\nIterations: %d\nRelative residual: %.12e\n"
               "Max solution error: %.12e\nConverged: %s\nTime: %.6f s\n",
               n, opt.random_solution ? "random" : "known", opt.eps, tau,
               processes, iterations, relative_residual, max_difference,
               converged ? "true" : "false", max_elapsed);
    }

    free(counts);
    free(offsets);
    free(a);
    free(b);
    free(x);
    free(answer);
    free(new_x);
    free(residual);
    MPI_Finalize();
    return converged ? 0 : 2;
}
