/*
 * particle.h
 *
 *  Created on: Mar 4, 2019
 *      Author: Christian Camacho
 */

#ifndef PARTICLE_H_
#define PARTICLE_H_

#include <vector>
#include "optim.h"

/* Solution structure */
struct Solution {
	double *x;    /* d-dimensional array */
	double eval;  /* value of the objective function */
};

class Particle {

public:

	Optim * optim;        /* the optimization problem */
	long int size;        /* problem size: number of dimensions of the functions */

	bool init;

	/*Solution variables*/
	//Each particle has to remember three vectors
	struct Solution current;  /* current position */
	struct Solution pbest;    /* personal best position */
	struct Solution lbest;    /* global best position (According to the topology) */

	std:: vector < Particle* > neighbours;  /* vector of neighbors particles */

	/*Velocity parameters of Standard PSO */
	double* velocity;             /* velocity */
	double phi_1, phi_2, inertia; /* parameters */

	Particle (Optim* problem);  /* empty constructor */
	~Particle();  				/* destructor */
	Particle (Optim* problem, double _phi_1, double _phi_2, double _inertia);  /* constructor */
	Particle (const Particle &p);  /* copy constructor */
	Particle& operator= (const Particle& p);  /* overriding of '=' */

	void  move(); 					//to be implemented
	double* getCurrentPosition();
	double  getCurrentEvaluation();
	double* getPbestPosition();
	double  getPbestEvaluation();
	void    evaluateSolution(); 	//to be implemented

	void addNeighbour(Particle* p);
	void findlbestParticle(); 		//to be implemented
	void updatelbestParticle(double* x, double eval);

	void initializeUniform(); 		//to be implemented
	void printPosition();

};

#endif /* PARTICLE_H_ */
