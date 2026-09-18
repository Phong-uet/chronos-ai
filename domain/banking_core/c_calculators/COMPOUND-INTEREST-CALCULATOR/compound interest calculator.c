#include <stdio.h>
#include <stdlib.h>
#include <stdbool.h>
#include <string.h>
#include <math.h>

int main()
{
    double A;
    double p;
    double r;
    double n;
    double t;

    printf("Enter your Principal amount: ");
    scanf("%lf", &p);

    printf("Enter your anual rate of interest: ");
    scanf("%lf", &r);
    r = r/100;

    printf("Enter the amount of times the interest is compounde per  year: ");
    scanf("%lf", &n);

    printf("Enter the number of years you want your interest to keep compounding: ");
    scanf("%lf", &t);

    A = p * pow((1 + r / n), n * t);

    printf("after %.1lf years, your total will be %.2lf", t, A);

}
