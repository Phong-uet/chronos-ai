#include <stdio.h>
#include <math.h>
#include <stdlib.h>

int main()
{
	float principal, interstRate, monthlyInterestRate;
	float emi, startBalance, interest, principalPaid, endingBalance;

	int numOfMonths, month;
	float interestArr[30], principalPaidArr[30], endingBalanceArr[30];

	printf("Enter amount of loan : ");
	scanf("%f", &principal);

	printf("Enter Interest rate per year : % ");
	scanf("%f", &interstRate);

	printf("Enter number of payments : ");
	scanf("%d", &numOfMonths);

	printf("========================AMORTIZATION SCHEDULE=====================\n");

	monthlyInterestRate = (float)(interstRate / (12*100.0));

		emi = principal * (monthlyInterestRate / (1 - pow( (1 + monthlyInterestRate) , (-numOfMonths) )));

	printf(" Monthly Payment: $%.2f ", emi);



	month = 1;
	while (month <= numOfMonths) {
	    interestArr[month - 1] = (startBalance * monthlyInterestRate);
    	    principalPaidArr[month - 1] = emi - interestArr[month - 1];
   	    endingBalanceArr[month - 1] = (startBalance - principalPaidArr[month - 1]);
            startBalance = endingBalanceArr[month - 1];
            month++;
}


	printf(" %10s %14s %10s %10s ", " Payment ", " Principal ", " Interest ", " Balance ");


	for(month = 1; month <= numOfMonths; month++)
	{

	printf(" %6d $%-10.2f $%-10.2f $%-12.2f ", month, principalPaidArr[month-1], interestArr[month-1], endingBalanceArr[month-1]);
}


printf(" Final Payment: $%.2f ", emi);

printf(" ");
return 0;
}
