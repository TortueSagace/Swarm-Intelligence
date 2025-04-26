/*
 * pso.cpp
 *
 *  Created on: Mar 4, 2019
 *      Author: Christian Camacho
 */

#include <stdlib.h>
#include <iostream>
#include <math.h>
#include <limits.h>
#include <string.h>
#include <vector>
#include <float.h>

#include "optim.h"
#include "particle.h"

// available functions
#define RASTRIGIN 0
#define ROSENBROCK 1

// available topologies
#define TOP_GBEST 0 //a.k.a star
#define TOP_RING 1  //a.k.a lbest
#define TOP_WHEEL 2

using namespace std;

Optim* problem;                // optimization problem/function
short problem_code;            // function indicator
short topology;                // topology indicator
void (*setNeighborhood)();     // pointer to neighborhood function

/* algorithm variables  */
long int iterations=0;
long int evaluations=0;
long int max_iterations=0;
long int max_evaluations=0;
long int seed = -1;

/* problem variable */
long int n = 0;                /* Problem dimension */
long int n_particles = 0;      /* Number of particles */

/* particle coefficients */
double inertia = 1;
double phi_1 = 1;
double phi_2 = 1;

/* particle swarm */
vector<Particle> swarm;
Particle *best_particle;        /* best particle */

struct Solution global_best;    /* best solution */

long int best_cost=LONG_MAX;    /* value of the best solution found */


/* Topologies */
void createRingTopology(){      //Every particle is neighbor of TWO adjacent particles
	int a,b;
	for(int i=0;i<n_particles;i++){
		a=i-1;
		b=i+1;
		if(i==0)
			a=n_particles-1;
		if(i==(n_particles-1))
			b=0;

		swarm[i].addNeighbour(&swarm[a]);
		swarm[i].addNeighbour(&swarm[b]);
	}

}

void createWheelTopology(){      //All particles are neighbors of one central particle
	for(int i=1;i<n_particles;i++){
		swarm[i].addNeighbour(&swarm[0]);
		swarm[0].addNeighbour(&swarm[i]);
	}
}

void createGbestTopology(){     //All particles are neighbor among them
	for(int i=0;i<n_particles;i++){
		for(int j=0;j<n_particles;j++){
			if(i!=j)
				swarm[i].addNeighbour(&swarm[j]);
		}
	}
}

/* Default parameters */
void setDefaultParameters(){
	problem_code = 1;          //RASTRIGIN 0, ROSENBROCK 1
	topology = 1;              //TOP_GBEST 0, TOP_RING 1, TOP_WHEEL 2
	setNeighborhood = createRingTopology;    //createGbestTopology, createRingTopology, createWheelTopology
	n = 2;					   //Minimum two particles, try a number between 2 and 100)
	seed = 2843;
	n_particles = 10;
	max_iterations = 100;
	inertia = 1;
	phi_1 = 1;
	phi_2 = 1;
}

/* Print parameters */
void printParameters(){
	string prob;
	if (problem_code == RASTRIGIN)
		prob = "Rastrigin";
	else
		prob = "Rosenbrock";

	cout << "\nParticle Swarm Optimization\n" << endl;
	cout << "\nParameters:\n"
			<< "\tproblem:   " << prob << "\n"
			<< "\tdimensions: " << n << "\n"
			<< "\tparticles:  " << n_particles << "\n"
			<< "\ttopology:   " << topology << "\n"
			<< "\titerations: " << max_iterations << "\n"
			<< "\tinertia:    " << inertia << "\n"
			<< "\tphi_1:      " << phi_1 << "\n"
			<< "\tphi_2:      " << phi_2 << "\n"
			<< "\tseed:       " << seed << "\n"
			<< endl;
}

void printUsage(){
	cout << "\nPSO Usage:\n";
	cout << "./pso <problem> --n <#dimensions> --particles <#particles> <topology> "
			"--iterations <#iterations> --inertia <inertia> --phi1 <phi1> "
			"--phi2 <phi2> --seed <seed> --help"
			<< endl;
	cout << "\tproblem:  --rastrigin | --rosenbrock" << endl;
	cout << "\ttopology: --gbest | --ring | --star" << endl;
	cout << "\tinertia: real (0,1]" << endl;
	cout << "\t--help: print usage and exit."<< endl;
	cout << "Example: ./pso  --rastrigin --n 20 --particles 30 --ring --iterations 100 "
			"--inertia 0.4 --phi1 0.5 --phi2 0.6 --seed 1242" << endl;
}

/* Read arguments from command line */
bool readArguments(int argc, char *argv[] ){

	setDefaultParameters();

	for(int i=1; i< argc ; i++){
		if(strcmp(argv[i], "--rastrigin") == 0){
			problem_code = RASTRIGIN;
		} else if(strcmp(argv[i], "--rosenbrock") == 0){
			problem_code = ROSENBROCK;
		} else if(strcmp(argv[i], "--n") == 0){
			n = atoi(argv[i+1]);
			i++;
		} else if (strcmp(argv[i], "--seed") == 0) {
			seed = atoi(argv[i+1]);
			i++;
		} else if (strcmp(argv[i], "--particles") == 0){
			n_particles = atoi(argv[i+1]);
			i++;
		} else if (strcmp(argv[i], "--ring") == 0){
			topology = TOP_RING;
			setNeighborhood=createRingTopology;
		} else if (strcmp(argv[i], "--gbest") == 0){
			topology = TOP_GBEST;
			setNeighborhood=createGbestTopology;
		} else if (strcmp(argv[i], "--wheel") == 0){
			topology = TOP_WHEEL;
			setNeighborhood=createWheelTopology;
		} else if (strcmp(argv[i], "--inertia") == 0){
			inertia = atof(argv[i+1]);
			i++;
		} else if (strcmp(argv[i], "--iterations") == 0){
			max_iterations = atoi(argv[i+1]);
			i++;
		} else if (strcmp(argv[i], "--evaluations") == 0){
			max_evaluations = atoi(argv[i+1]);
			i++;
		} else if (strcmp(argv[i], "--phi1") == 0) {
			phi_1 = atof(argv[i+1]);
			i++;
		} else if (strcmp(argv[i], "--phi2") == 0) {
			phi_2 = atof(argv[i+1]);
			i++;
		} else if (strcmp(argv[i], "--help") == 0) {
			//printUsage();
			return(false);
		} else {
			cout << "Parameter " << argv[i] << " not recognized.\n";
			return(false);
		}
	}
	return(true);
}

void initialize() {
	if (problem_code == 0) {
		problem = new Rastrigin(n);
	} else if (problem_code == 1) {
		problem = new Rosenbrock(n);
	}

	/*Initialize global best*/
	global_best.x = new double[n];
	for(int i=0;i<n;i++)
		global_best.x[i] = 0;
	global_best.eval=DBL_MAX;              //initialized to a large value

	//Test functions constraint
	if (problem_code == ROSENBROCK && n < 2 ) {
		cerr << "\nError: The number of dimensions for Rosenbrock's function should be grater than 1.\n";
	}

}

/*********** Exercise 1 starts here ***********/
/* Update global best solution found */
void updateGlobalBest(double* new_x, double eval){
}

/* Move the swarm */
void moveSwarm() {
	//particles will move applying the rules for new velocity and position
	//do not forget to update the global_best particle whenever is the case
}

/* Termination condition */
bool terminationCondition() {
	return true;
}
/*********** Exercise 1 ends here ***********/

/*Create swarm structure*/
void createSwarm (){
	Particle p(problem);
	cout << "Creating swarm.\n\n";
	for (int i=0;i<n_particles;i++) {
		p = Particle(problem, phi_1, phi_2, inertia);
		//cout << "\tParticle [" << i << "] evaluation: " << p.getPbestEvaluation() << endl;
		swarm.push_back(p);
		if (global_best.eval > p.getPbestEvaluation()){
			updateGlobalBest(p.getPbestPosition(), p.getPbestEvaluation());
			best_particle = &p;
		}
	}
	setNeighborhood();
	cout << "\n\tBest initial solution quality: " << global_best.eval << "\n"<< endl;
}

/*Free memory used*/
void freeMemory(){
	delete problem;
	delete [] global_best.x;
}

int main(int argc, char *argv[]) {
	if(!readArguments(argc, argv)){
		printUsage();
		exit(0);
	}
	printParameters();
	srand(seed);

	initialize();
	createSwarm();

	//Iterations loop
	while(!terminationCondition()){
		moveSwarm();
		evaluations=evaluations + n_particles;
		iterations++;
	}

	cout << "\n\n\tBest solution found: " << global_best.eval << " after " <<  iterations << " iterations "<< endl;
	freeMemory();   // Free memory.
	cout << "\nEnd of PSO execution.\n" << endl;
}

