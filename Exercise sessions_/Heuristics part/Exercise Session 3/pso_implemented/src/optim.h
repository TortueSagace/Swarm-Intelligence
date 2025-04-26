/*
 * optim.h
 *
 *  Created on: Mar 4, 2019
 *      Author: Christian Camacho
 */

#ifndef OPTIM_H_
#define OPTIM_H_

/* problem superclass */
/* will be instantiated as Rastrigin or Rosenbrock */
class Optim {

public:

	long int n;          /* number of dimensions */
	double lower_bound;  /* lower bound for the solution coefficients */
	double upper_bound;  /* upper bound for the solution coefficients */
	Optim ();
	Optim (long int _n);
	Optim (const Optim &o);
	virtual ~Optim();

	long int getSize();
	double getRandomX();  /* get a random number in the range [lower_bound, upper_bound] */

	virtual double evaluate(double *v)=0; /* evaluate solution value on function */
};


/* Rastrigin class */
/* Actual subclass to use */
class Rastrigin: public Optim {
public:
	/* constructor */
	Rastrigin(long int _n):Optim(_n){
		lower_bound=-5.12;
		upper_bound=5.12;
		//std::cout << "Loading Rastrigin function."<< std::endl;
	}
	double evaluate(double *v);
};

/* Rosenbrock class */
/* Actual subclass to use */
class Rosenbrock: public Optim {
public:
	Rosenbrock(long int _n):Optim(_n){
		lower_bound=-30;
		upper_bound=30;
		//std::cout << "Loading Rosenbrock function."<< std::endl;
	}
	double evaluate(double *v);
};

#endif /* OPTIM_H_ */
