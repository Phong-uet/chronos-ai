#include <stdio.h>
#include <stdlib.h>
#include <math.h>

struct loan
{
        double interest;
        double bal;
        double prin;
};

struct loan payments[100];

int main()
{
        double balance, interestRate;

        int n;

        double A, r;


        printf("\nEnter amount of loan : $ ");
        scanf("%lf", &balance);
        printf("Enter interest rate per period : %% ");
        scanf("%lf", &interestRate);
        printf("Enter number of payments : ");
        scanf("%d", &n);


        r = interestRate / 1200;


        A = balance * ((r * pow(1 + r, n)) / (pow(1 + r, n) - 1));


        payments[0].bal = balance;


        printf("\nMonthly payment should be $%.2f\n\n", A);
        printf("=================AMORTIZATION SCHEDULE====================\n\n");
        printf(" %-8s %10s %13s %10s %10s \n", "#", " Payment ", " Principal ", " Interest ", " Balance ");

        int i;

        i = 1;
        while (i <= n)
        {
                payments[i].interest = payments[i - 1].bal * r;
                 payments[i].prin = A - payments[i].interest;
                payments[i].bal = payments[i - 1].bal - payments[i].prin;

                  printf("\n %-10d $%-10.2lf $%-10.2lf $%-10.2lf $%-12.2lf ", i, A, payments[i].prin, payments[i].interest, payments[i].bal);

                i++;
}


printf("\n\n");
return 0;
}
