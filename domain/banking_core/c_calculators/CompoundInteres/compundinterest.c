#include <stdio.h>
#include <math.h>

int main()
{
    printf("*****COMPOUND INTEREST CALCULATOR*****\n\n");

    double principal, rate, total = 0.0;
    int year, timesCoumpounded = 0;

    printf("How much would you like to invest? ");
    scanf("%lf", &principal);

    printf("Enter the inerest rate you desire: ");
    scanf("%lf", &rate);
     if (rate > 1)
     { rate = rate / 100;
    }

    printf("How long would you like to invest (in years)? ");
    scanf("%d", &year);

    printf("How many times should it be compounded in a year (annually, semiannually, etc.)? ");
    scanf("%d", &timesCoumpounded);

    total = principal * pow((1 + (rate/timesCoumpounded)), (timesCoumpounded * year));

    printf("%lf", total);

    return(0);
}


