/**
 * mortgage.c - Loan amortization schedule and compound interest tables.
 */

#include <stdio.h>

double compute_mortgage_payment(double loan_amount, double annual_rate, int months) {
    if (months <= 0 || loan_amount <= 0.0) {
        return 0.0;
    }

    double monthly_rate = annual_rate / 12.0 / 100.0;
    double factor = 1.0;

    for (int i = 0; i < months; i++) {
        factor *= (1.0 + monthly_rate);
    }

    double monthly_payment = loan_amount * (monthly_rate * factor) / (factor - 1.0);

    for (int m = 1; m <= months; m++) {
        double interest_part = loan_amount * monthly_rate;
        double principal_part = monthly_payment - interest_part;
        loan_amount -= principal_part;

        if (loan_amount < 0.0) {
            loan_amount = 0.0;
            break;
        }
    }

    return monthly_payment;
}
