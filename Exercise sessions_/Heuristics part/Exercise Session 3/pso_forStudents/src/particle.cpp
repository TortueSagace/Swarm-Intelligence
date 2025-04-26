/*
 * particle.cpp
 *
 *  Created on: Mar 4, 2019
 *      Author: Christian Camacho
 */

#include <float.h>
#include <iostream>

#include "optim.h"
#include "particle.h"

using namespace std;

/* random function for values in [0,1] */
double getRandom01(){
	double rr = (double) rand()/RAND_MAX;
	return(rr);
};

/* Default constructor*/
Particle::Particle(Optim* problem){
	optim = problem;
	size= optim->getSize();
	phi_1 = 0;
	phi_2 = 0;
	inertia=0;
	velocity = {0}; //new double[size];
	init=false;
}

/* Constructor*/
Particle::Particle (Optim* problem, double _phi_1, double _phi_2, double _inertia){
	optim = problem;
	size= optim->getSize();

	current.x = new double[size];
	pbest.x = new double[size];
	lbest.x = new double[size];
	current.eval = DBL_MAX;
	pbest.eval = DBL_MAX;
	lbest.eval = DBL_MAX;

	velocity = new double[size];

	phi_1 = _phi_1;
	phi_2 = _phi_2;
	inertia=_inertia;

	initializeUniform();
	//printSolution();
	init = true;
}

/* Copy constructor */
Particle::Particle (const Particle &p){

	optim = p.optim;
	size = p.size;

	if(!init){
		current.x = new double[size];
		pbest.x = new double[size];
		lbest.x = new double[size];
		velocity = new double[size];
	}

	for(int i=0; i<size;i++){
		current.x[i] = p.current.x[i];
		pbest.x[i] = p.pbest.x[i];
		lbest.x[i] = p.lbest.x[i];
		velocity[i] = p.velocity[i];
	}

	current.eval = p.current.eval;
	pbest.eval = p.pbest.eval;
	lbest.eval = p.lbest.eval;

	inertia=p.inertia;
	phi_1 = p.phi_1;
	phi_2 = p.phi_2;
	init = true;

}

/* destructor */
Particle::~Particle(){
	if(init){
		delete[] current.x;
		delete[] pbest.x;
		delete[] lbest.x;
		delete[] velocity;
	}
	init=false;
}

/* overriding of '=' operator for particles
   (now 'p1 = p2;' does what one would expect) */
Particle& Particle::operator= (const Particle& p){
	if (this != &p) {
		optim = p.optim;
		size = p.size;

		if(!init){
			current.x = new double[size];
			pbest.x = new double[size];
			lbest.x = new double[size];
			velocity = new double[size];
		}

		for(int i=0; i<size;i++){
			current.x[i] = p.current.x[i];
			pbest.x[i] = p.pbest.x[i];
			lbest.x[i] = p.lbest.x[i];
			velocity[i] = p.velocity[i];
		}

		current.eval = p.current.eval;
		pbest.eval = p.pbest.eval;
		lbest.eval = p.lbest.eval;

		inertia=p.inertia;
		phi_1 = p.phi_1;
		phi_2 = p.phi_2;
		init = true;
	}
	return *this;
}

/*********** Exercise 1 starts here ***********/
/* Initialize particle */
// The initial position of a particle is a random point in the search space
void Particle::initializeUniform(){
	//do no forget to evaluate the solutions after the initialization
}

/* Generate new solutions by updating particles positions */
/* Note: remember that each dimension of the problem is bounded between a maximum and minimum value, 
 * if the new position of a particle exceeds the bounds, it has to be reallocated inside the search space.
 */
void Particle::move(){
	//do no forget to evaluate particles' positions after they have been updated
}

/* Find the local best particle */
void Particle::findlbestParticle(){
	//do not forget to update the particle's variable lbest.x and lbest.eval (see particle.h)
}

// Self-explanatory
void Particle::evaluateSolution() {
	//optim->evaluate(double *v) returns the cost of the solution, where *v is a solution to the problem
}

/*  */
void Particle::updatelbestParticle(double* x, double eval){
}
/*********** Exercise 1 ends here ***********/


double* Particle::getCurrentPosition() {
	return(current.x);
}

double Particle::getCurrentEvaluation(){
	return(current.eval);
}

double* Particle::getPbestPosition() {
	return(pbest.x);
}

double Particle::getPbestEvaluation(){
	return(pbest.eval);
}

void Particle::printPosition(){
	cout << "Solution:" << current.eval << endl;
	for(int i=0; i<size; i++){
		cout << current.x[i] << "  ";
	}
	cout << endl;
}

void Particle::addNeighbour(Particle* p){
	neighbours.push_back(p);
}
