/*
 * optim.cpp
 *
 *  Created on: Mar 4, 2019
 *      Author: Christian Camacho
 */

#include <stdlib.h>
#include <math.h>
#include "optim.h"

using namespace std;

/* Constructor*/
Optim::Optim (long int _n){
	n=_n;
	lower_bound=0;
	upper_bound=0;
};

/* Destructor*/
Optim::~Optim (){
};

/* Return the number of dimensions*/
long int Optim::getSize(){
	return(n);
}

/* Copy Constructor*/
Optim::Optim (const Optim &o){
	n=o.n;
	lower_bound=o.lower_bound;
	upper_bound=o.upper_bound;
};


/* get a random number in the range [lower_bound, upper_bound] */
double Optim::getRandomX(){
	double rr = ((double) rand()/RAND_MAX) * (upper_bound-lower_bound) + lower_bound;
	return(rr);
};

/* compute solution value on the Rastrigin function
   INPUT: coefficient vector of a solution v
   OUTPUT: f(v)
 */
double Rastrigin::evaluate(double *v) {
	double val = 0.0;
	for (int i = 0; i < n; i++) {
		val += pow(v[i], 2) - 10.0 * cos(2.0 * M_PI * v[i]);
	}
	return val;
}

/* compute solution value on the Rosenbrock function
   INPUT: coefficient vector of a solution v
   OUTPUT: f(v)
 */
double Rosenbrock::evaluate(double *v) {
	double val = 0.0;
	for (int i = 0; i < n-1; i++) {
		val += 100.0 * pow(v[i+1] - pow(v[i], 2), 2) + pow(1.0 - v[i], 2);
	}
	return val;
}
