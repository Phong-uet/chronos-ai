#include <math.h>
#include <stdio.h>

int main()
{
    double amount, r, t;
    printf("Enter amount of loan: $ ");
    scanf("%lf", &amount);
    printf("Enter Interest rate per year: %% ");
    scanf("%lf", &r);
    printf("Enter Number of payments: ");
    scanf("%lf", &t);

    r = r / 100;
    r = r / 12;

    double monthlyPayment = (amount * r) / (1 - pow(1 + r, -t));

    printf("\nMonthly payment should be %.2lf\n", monthlyPayment);

    double interest, p;

    printf("========================AMORTIZATION SCHEDULE=====================\n");
    printf("#\tPayment\t\tPrincipal\tInterest\tBalance\n");
    for (int i = 1; i <= t; i++) {
        interest = r * amount;
        p = monthlyPayment - interest;
        amount = amount - p;
        printf("%d\t$%.2lf\t\t$%.2lf\t\t$%.2lf\t\t$%.2lf\n", i, monthlyPayment, p, interest, amount);
    }

    return 0;
}

