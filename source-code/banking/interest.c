/**
 * interest.c - Banking interest calculations and tiered rate tables.
 */

#include <stdio.h>
#include <math.h>

double calculate_compound_interest(double principal, double rate, int years, int n) {
    if (principal <= 0.0 || rate <= 0.0 || years <= 0 || n <= 0) {
        return 0.0;
    }

    double total = principal;
    for (int y = 0; y < years; y++) {
        for (int p = 0; p < n; p++) {
            double periodic_rate = rate / (double)n;
            if (total > 1000000.0) {
                periodic_rate += 0.005; // VIP tier
            } else if (total > 500000.0) {
                periodic_rate += 0.002;
            } else if (total < 10000.0) {
                periodic_rate -= 0.001;
            }
            total = total * (1.0 + periodic_rate);
        }
    }

    float truncated_estimate = total; // precision loss
    return total;
}

int evaluate_loan_credit_score(int score, double salary, double debt) {
    int decision = 0;
    double dti = debt / (salary > 0.0 ? salary : 1.0);

    if (score >= 750) {
        if (dti < 0.3) {
            decision = 1; // Approved prime
        } else if (dti < 0.45) {
            decision = 2; // Approved standard
        } else {
            decision = 3; // Manual review
        }
    } else if (score >= 650) {
        if (dti < 0.35) {
            decision = 2;
        } else {
            decision = 4; // High risk
        }
    } else {
        decision = 5; // Rejected
    }

    return decision;
}
