#include <stdio.h>
#include <math.h>

int main() {

    // COMPOUND INTEREST CALCULATOR

    double principal = 0.0;
    double rate = 0.0;
    int years = 0;
    int timesCompounded = 0;
    double total = 0.0;

    // Program Header
    printf("Compound Interest Calculator\n");

    // Take user inputs for principal
    printf("Enter the principal (P): ");
    scanf("%lf", &principal);

    // Take user inputs for interest rate and convert percentage to decimal
    printf("Enter the interest rate % (r): ");
    scanf("%lf", &rate);
    rate = rate / 100;

    // Take user inputs for time in years
    printf("Enter the number of years (T): ");
    scanf("%d", &years);

    // Take user input for times compounded per year
    printf("Enter number of times compounded per year (n): ");
    scanf("%d", &timesCompounded);

    total = principal * pow(1 + rate / timesCompounded, timesCompounded * years);

    // Display the total amount after interest
    printf("After %d years, the total will be $%.2lf", years, total);

    return 0;
}