/*
 *n01431140
 *11/12/2020
 *This program calculates the amortization of a loan, printing it as a monthly payment table.
*/

#include <stdio.h>
#include <math.h>

#define FLUSH while(getchar() != '\n');//clears buffer

//min and max limits for input
#define MAX_TERM 30
#define MIN_TERM 1
#define MAX_PRINCIPLE 2000000.00
#define MIN_PRINCIPLE 100.00
#define MAX_APR 30.0
#define MIN_APR 1.0

void GetTerm(int* t);
void GetPrinciple(double* p);
void GetAPR(double* i);
void CalcPayment(int n, double a, double r, double* pmt);
void CompAmortization(int term, double principle, double apr, double payment);

int main(void)
{

	int term;
	double principle;
	double apr;
	double monthlyPayment;

	GetTerm(&term);//gets user value for the term in months
	GetPrinciple(&principle);//gets principle
	GetAPR(&apr);//gets apr
	CalcPayment(term, principle, apr, &monthlyPayment);//calculates the monthly payment

	CompAmortization(term, principle, apr, monthlyPayment);//prints amortization table and prints it
	
	return 0;
}//end main

/*
 *gets user input for the term in years
 *checks if input is within set range
 *converts to months sends to main with pointer
 */
void GetTerm(int* t)
{ 
	
	int years;

	jmp:	
	
	printf("Enter the term in years:\n");
	scanf("%d", &years);
	
	if((years >= MIN_TERM) && (years <= MAX_TERM)) 
	{
		*t = (years * 12);	
	}	
	else
	{	
		printf("Error: number must be within range [%d,%d]\n", MIN_TERM, MAX_TERM);
		FLUSH;
		goto jmp;
	}
	return;
}

/*
 *gets user input for principle
 *checks if input is within set range
 *sends principle to main  with pointer
 */
void GetPrinciple(double* p) 
{

	double principle;
	
	jmp:

	printf("Enter the loan principle:\n");
	scanf("%lf", &principle);

	if((principle >= MIN_PRINCIPLE) && (principle <= MAX_PRINCIPLE))
	{
		*p = principle;
	}
	else
	{
		printf("Error: number must be within range [%.2lf,%.2lf]\n", MIN_PRINCIPLE, MAX_PRINCIPLE);
		FLUSH;
		goto jmp;
	}	
	return;
}

/*
 *gets user input for apr
 *checks input is within set range
 *sends apr to main with pointer
 */
void GetAPR(double* i) 
{
	double intrest;

	jmp:

	printf("Enter the APR:\n");
	scanf("%lf", &intrest);

	if((intrest >= MIN_APR) &&(intrest <= MAX_APR))
	{
		*i = intrest;
	}
	else
	{
		printf("Error: number must be within range [%.1lf,%.1lf]\n", MIN_APR, MAX_APR);
		FLUSH;
		goto jmp;
	}

	return;
}

/*
 *calculates monthly payment and sends to main with pointer
 */
void CalcPayment(int n, double a, double r, double* pmt) 
{

	double nd = (double) n;
	double rPlusOne;
	double payment;

	r =((r / 100.0) / 12);
	rPlusOne = (r + 1.0);

	payment = (pow(rPlusOne,nd) - 1.0);
	payment = (payment / (r * pow(rPlusOne, nd)));
	payment = (a / payment);

	*pmt = payment;	

	return;
} 

/*
 *for each month calculates intrest payment and principle payment
 *tracks total payments
 *prints each month, intrest payment, princ payment, and principle total
 *prints total payments
 */
void CompAmortization(int term, double principle, double apr, double payment) 
{

	int i;
	double intPmt;
	double princPmt;
	double intTot = 0;
	double princTot = 0;

	apr = ((apr / 100) / 12);
	printf("| Pmt | Intrest | PrincPmt |   Balance   |\n");
	for(i = 1; i <= term; i++)
	{
		intPmt = (apr * principle);
		princPmt = (payment - intPmt);
		principle = (principle - princPmt);
	
		princTot = (princTot + princPmt);
		intTot = (intTot + intPmt);
		
		printf("| %03d | %7.2lf | %8.2lf | %11.2lf |\n", i, intPmt, princPmt, principle);
	}
	printf("Total cost of this loan: $%10.2lf\n", (intTot + princTot));
	printf("Total cost of intrest:   $%10.2lf\n", intTot);
	printf("Total cost of principle: $%10.2lf\n", princTot); 	
	
return;
}



