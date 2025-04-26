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
	for(int i=0; i<size; i++){
		current.x[i]=optim->getRandomX();
		pbest.x[i]=current.x[i];
		velocity[i]=0;
	}
	evaluateSolution();
}

/* Generate new solutions by updating particles positions */
/* Note: remember that each dimension of the problem is bounded between a maximum and minimum value, 
 * if the new position of a particle exceeds the bounds, it has to be reallocated inside the search space.
 */
void Particle::move(){
	double u1, u2;

	findlbestParticle();      //the lbest depends on the topology

	//remember that each particle is an n dimensional vector
	for (int i=0;i<size;i++) {
		u1=getRandom01();
		u2=getRandom01();
		velocity[i] = (inertia*velocity[i]) + phi_1 * u1 * (pbest.x[i] - current.x[i]) + phi_2 * u2 * (lbest.x[i] - current.x[i]);
		current.x[i] = current.x[i] + velocity[i];

		//values assigned to the variables cannot be outside the function bounds
		if(current.x[i] < optim->lower_bound)
			current.x[i]= optim->lower_bound;
		if(current.x[i] > optim->upper_bound)
			current.x[i]= optim->upper_bound;
	}

	evaluateSolution();
}

/* Find the local best particle */
void Particle::findlbestParticle(){
	double aux_eval;
	int best=-1;

	if(pbest.eval < lbest.eval){
		updatelbestParticle(pbest.x, pbest.eval);
	}
	aux_eval=lbest.eval;
	for(unsigned int i=0; i<neighbours.size();i++){
		if(aux_eval > neighbours[i]->getPbestEvaluation()){
			best =i;
		}
	}

	if(best!=-1)
		updatelbestParticle(neighbours[best]->getPbestPosition(), neighbours[best]->getPbestEvaluation());
}


void Particle::evaluateSolution() {
	current.eval = optim->evaluate(current.x);
	if (current.eval < pbest.eval) {
		for (int i=0;i<size;i++) {
			pbest.x[i] = current.x[i];
		}
		pbest.eval=current.eval;
	}
}

/* update lbest solution
   INPUT: * coefficient vector x and the evaluation of the objective function, i.e. eval = f(x)
 */
void Particle::updatelbestParticle(double* x, double eval){
	for(int j=0;j <size;j++){
		lbest.x[j]= x[j];
	}
	lbest.eval = eval;
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
