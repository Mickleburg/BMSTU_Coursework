#include <math.h>
#include <omp.h>
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

static void fill_matrix(double *a, int n) {
    #pragma omp parallel for collapse(2)
    for (int i = 0; i < n; ++i)
        for (int j = 0; j < n; ++j)
            a[(size_t)i * n + j] = i == j ? 2.0 : 1.0;
}

static void multiply(const double *a, const double *x, double *result, int n) {
    #pragma omp parallel for schedule(static)
    for (int i = 0; i < n; ++i) {
        double sum = 0.0;
        for (int j = 0; j < n; ++j) sum += a[(size_t)i * n + j] * x[j];
        result[i] = sum;
    }
}

static double dot(const double *a, const double *b, int n) {
    double sum = 0.0;
    #pragma omp parallel for reduction(+:sum)
    for (int i = 0; i < n; ++i) sum += a[i] * b[i];
    return sum;
}

int main(int argc, char **argv) {
    Options opt;
    if (!parse_options(argc, argv, &opt)) {
        usage(argv[0]);
        return 1;
    }

    omp_set_dynamic(0);
    int threads = 1;
    #pragma omp parallel
    {
        #pragma omp single
        threads = omp_get_num_threads();
    }

    int n = opt.n;
    double *a = malloc((size_t)n * n * sizeof(*a));
    double *b = malloc((size_t)n * sizeof(*b));
    double *x = calloc((size_t)n, sizeof(*x));
    double *answer = malloc((size_t)n * sizeof(*answer));
    double *residual = malloc((size_t)n * sizeof(*residual));
    if (!a || !b || !x || !answer || !residual) {
        fprintf(stderr, "Not enough memory.\n");
        return 1;
    }

    fill_matrix(a, n);
    #pragma omp parallel for
    for (int i = 0; i < n; ++i)
        answer[i] = opt.random_solution ? sin(2.0 * acos(-1.0) * i / n) : 1.0;
    multiply(a, answer, b, n);

    double norm_b = sqrt(dot(b, b, n));
    if (norm_b == 0.0) norm_b = 1.0;
    double tau = 0.1 / n;
    double relative_residual = 0.0;
    int iterations = 0;
    int converged = 0;
    double started = omp_get_wtime();

    for (;;) {
        // Check the residual of the current x before updating it.
        multiply(a, x, residual, n);
        #pragma omp parallel for
        for (int i = 0; i < n; ++i) residual[i] -= b[i];

        relative_residual = sqrt(dot(residual, residual, n)) / norm_b;
        if (relative_residual < opt.eps) {
            converged = 1;
            break;
        }
        if (!isfinite(relative_residual) || iterations == opt.max_iter) break;
        #pragma omp parallel for
        for (int i = 0; i < n; ++i) x[i] -= tau * residual[i];
        ++iterations;
    }
    double elapsed = omp_get_wtime() - started;

    double max_difference = 0.0;
    for (int i = 0; i < n; ++i) {
        double difference = fabs(x[i] - answer[i]);
        if (difference > max_difference) max_difference = difference;
    }

    printf("Implementation: OpenMP\nMethod: simple iteration\nMatrix size: %d\n"
           "Task: %s\nEpsilon: %.12e\nTau: %.12e\n"
           "Threads: %d\nIterations: %d\nRelative residual: %.12e\n"
           "Max solution error: %.12e\nConverged: %s\nTime: %.6f s\n",
           n, opt.random_solution ? "random" : "known", opt.eps, tau,
           threads, iterations, relative_residual, max_difference,
           converged ? "true" : "false", elapsed);

    free(a);
    free(b);
    free(x);
    free(answer);
    free(residual);
    return converged ? 0 : 2;
}
