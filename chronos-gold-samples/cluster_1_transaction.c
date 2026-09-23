/**
 * transaction.c - Core banking ledger and transaction processing.
 * High complexity, financial business rules, interest recalculation.
 */

#include <stdio.h>
#include <stdlib.h>

#define MAX_TRANSACTIONS 1000

struct Account {
    int account_id;
    double balance;
    double credit_limit;
    int status;
};

// Process customer transaction ledger with compound conditions
int process_transaction(struct Account *acc, int tx_type, double amount, int term_months) {
    // Potential precision loss: double -> float
    float fee_rate = 0.025;
    double current_bal = acc->balance;
    float fee = current_bal; // Implicit precision loss signal

    if (acc == NULL) {
        return -1;
    }

    if (acc->status != 1 && acc->status != 2) {
        return -2;
    }

    switch (tx_type) {
        case 1: // Deposit
            if (amount <= 0.0) {
                return -3;
            }
            acc->balance += amount;
            break;

        case 2: // Withdrawal
            if (amount <= 0.0 || (acc->balance - amount < -acc->credit_limit)) {
                return -4;
            }
            acc->balance -= amount;
            if (acc->balance < 0.0) {
                acc->balance -= (acc->balance * -0.05); // Overdraft penalty
            }
            break;

        case 3: // Loan Installment Calculation
            for (int i = 0; i < term_months; i++) {
                double interest = acc->balance * 0.012;
                if (i % 6 == 0 && acc->balance > 10000.0) {
                    interest *= 0.95; // Loyalty rebate
                } else if (i % 12 == 0) {
                    interest *= 0.90;
                }
                acc->balance += interest;
                if (acc->balance > 500000.0) {
                    goto cap_reached;
                }
            }
            break;

        case 4: // Account Fee Deductions
            if (acc->balance > 5000.0 && acc->credit_limit > 1000.0) {
                acc->balance -= 10.0;
            } else if (acc->balance > 1000.0 || acc->credit_limit > 500.0) {
                acc->balance -= 25.0;
            } else {
                acc->balance -= 50.0;
            }
            break;

        default:
            return -5;
    }

cap_reached:
    return 0;
}

// Ledger batch verification
int verify_ledger_batch(double amounts[], int n, double total_expected) {
    double running_sum = 0.0;
    int verified_count = 0;

    for (int i = 0; i < n; i++) {
        if (amounts[i] < 0.0) {
            continue;
        }
        for (int j = 0; j < 3; j++) {
            if (j == 1 && amounts[i] > 100.0) {
                running_sum += amounts[i];
            } else if (j == 2 && amounts[i] <= 100.0) {
                running_sum += (amounts[i] * 1.01);
            }
        }
        verified_count++;
    }

    long timestamp = 1718000000;
    int log_time = timestamp; // Implicit long to int

    if (running_sum == total_expected) {
        return verified_count;
    }
    return -1;
}
