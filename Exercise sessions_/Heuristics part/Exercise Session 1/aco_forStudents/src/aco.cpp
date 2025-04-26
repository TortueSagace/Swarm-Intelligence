/*
 * aco.cpp
 *
 *  Created on: Feb 15, 2020
 *      Author: Christian Camacho
 */

#include <stdlib.h>
#include <iostream>
#include <math.h>
#include <limits.h>
#include <string.h>
#include <vector>

#include "tsp.h"
#include "ant.h"


using namespace std;

char * instance_file=NULL;
TSP* tsp;

/* Probabilistic rule related variables */
double  ** pheromone;   	/* pheromone matrix */
double  ** heuristic;  		/* heuristic information matrix */
double  ** probability;    	/* combined value of pheromone and  heuristic information */
double  initial_pheromone = 1.0;
double   alpha;
double   beta_par;
double   rho;
long int ants;
long int seed = -1;


long int max_iterations;
long int iterations=0;
long int max_tours;
long int tours=0;


vector<Ant> colony;		                /* Colony of virtual ants */
Ant best_ant;
long int best_tour_length=LONG_MAX;     /* Shortest tour found so far */

/* Default parameters */
void setDefaultParameters(){
	alpha=1.0;
	beta_par=1.0;
	rho=0.2;
	ants=10;
	max_iterations=0;
	max_tours=10000;
	instance_file=NULL;
	seed = (long int) time(NULL);
}

/* Print default parameters */
void printParameters(){
	cout << "\nACO parameters:\n"
			<< "  ants: "  << ants << "\n"
			<< "  alpha: " << alpha << "\n"
			<< "  beta: "  << beta_par << "\n"
			<< "  rho: "   << rho << "\n"
			<< "  tours: " << max_tours << "\n"
			<< "  iterations: "   << max_iterations << "\n"
			<< "  seed: "   << seed << "\n"
			<< "  initial pheromone: "   << initial_pheromone << "\n"
			<< endl;
}

void printHelp(){
	cout << "\nACO Usage:\n"
			<< " ./aco --ants <int> --alpha <float> --beta <float> --rho <float> --tours <int> --iterations <int> --seed <int> --instance <path>\n\n"
			<< "Example: ./aco --tours 2000 --seed 123 --instance Instances/eil51.tsp\n\n"
			<< "\nACO flags:\n"
			<< "   --ants: Number of ants to use in every iteration.\n"
			<< "   --alpha: Alpha parameter (float). Default=1.\n"
			<< "   --beta: Beta parameter (float). Default=1.\n"
			<< "   --rho: Rho parameter (float). Defaut=0.2.\n"
			<< "   --tours: Maximum number of tours to build (integer).\n"
			<< "   --iterations: Maximum number of iterations to perform (integer).\n"
			<< "   --seed: Random seed generator (positive integer).\n"
			<< "   --instance: Path to the instance file\n"
			<< "\nACO other parameters:\n"
			<< "   initial pheromone: "   << initial_pheromone << "\n"
			<< endl;
}


/* Read arguments from command line */
bool readArguments(int argc, char *argv[] ){

	setDefaultParameters();

	for(int i=1; i< argc ; i++){
		if(strcmp(argv[i], "--ants") == 0){
			ants = atol(argv[i+1]);
			i++;
		} else if(strcmp(argv[i], "--alpha") == 0){
			alpha = atof(argv[i+1]);
			i++;
		} else if(strcmp(argv[i], "--beta") == 0){
			beta_par = atof(argv[i+1]);
			i++;
		} else if(strcmp(argv[i], "--rho") == 0) {
			rho = atof(argv[i+1]);
			i++;
		} else if(strcmp(argv[i], "--iterations") == 0) {
			max_iterations = atol(argv[i+1]);
			i++;
		} else if(strcmp(argv[i], "--tours") == 0) {
			max_tours = atol(argv[i+1]);
			i++;
		} else if(strcmp(argv[i], "--seed") == 0) {
			seed = atol(argv[i+1]);
			i++;
		}else if(strcmp(argv[i], "--instance") == 0) {
			instance_file = argv[i+1];
			i++;
		}else if(strcmp(argv[i], "--help") == 0) {
			printHelp();
			return(false);
		}else{
			cout << "Parameter " << argv[i] << "no recognized.\n";
			return(false);
		}
	}
	if(instance_file==NULL){
		cout << "No instance file provided.\n";
		return(false);
	}
	printParameters();
	return(true);
}

void printPheromone () {
	long int i, j;
	long int size = tsp->getSize();

	printf("\nPheromone:\n");
	for ( i = 0 ; i < size ; i++ ) {
		for ( j = 0 ; j < size ; j++ ) {
			printf(" %4.4lf ", pheromone[i][j]);
		}
		printf("\n");
	}
}

void printProbability () {
	long int i, j;
	long int size = tsp->getSize();

	printf("\nProbability:\n");
	for ( i = 0 ; i < size ; i++ ) {
		for ( j = 0 ; j < size ; j++ ) {
			printf(" %4.4lf ", probability[i][j]);
		}
		printf("\n");
	}
}

/* Create colony of ants */
void createColony (){
	cout << "Creating colony of ants.\n\n";
	for (int i = 0 ; i < ants ; i++ ) {
		// Add element at the end
		colony.push_back(Ant(tsp, probability, &seed)); // See class Ant
	}
}

/* Initialize pheromone to t_0 */
void initializePheromoneMatrix( double initial_value ) {
	long int size = tsp->getSize();                  //number of cities
	pheromone = new double * [size];                 //columns in the pheromone matrix
	for (int i = 0 ; i < size ; i++ ) {
		pheromone[i] = new double [size];            //rows in the pheromone matrix
		for (int j = 0  ; j < size ; j++ ) {
			if (i==j) pheromone[i][i] = 0.0;         //zeros in the diagonal
			else pheromone[i][j] = initial_value;
		}
	}
}

/*** EXERCISE 1 starts here ***/

// Initialize the heuristic information matrix.
//You can use void initializePheromoneMatrix(double initial_value) as an example of how to do it.
void initializeHeuristicMatrix () {
	//use the 2D array double ** heuristic defined above
}

// Initialize the probability matrix to zero.
void initializeProbabiltyMatrix() {
	//use the 2D array double ** probability defined above
}

// Compute the probability matrix for the next iteration
// The idea is to have computed the product of pheromones and heuristic information in double ** probability 
// This product is the numerator of the random proportional rule.
void calculateProbabilityMatrix () {
	//use the 2D array double ** probability
}

// (self-explanatory)
void evaporatePheromone(){
}

// (self-explanatory)
void depositPheromone(){
}

/* Check termination condition based on iterations or tours.
 * one of the criteria must be active ( =! 0).*/
bool terminationCondition(){
	return true;
}

/*Free memory used*/
void freeMemory(){
//	for(int i=0; i < tsp->getSize(); i++) {
//		delete[] pheromone[i];
//		delete[] heuristic[i];
//		delete[] probability[i];
//	}
//	delete tsp;
//	delete[] pheromone;
//	delete[] heuristic;
//	delete[] probability;
}

/*** EXERCISE 1 ends here ***/

/* Main program */
int main(int argc, char *argv[] ){
	if(!readArguments(argc, argv)){
		exit(1);
	}

	/* New TSP object (see constructor method in tsp class) */
	tsp= new TSP (instance_file);

	initializePheromoneMatrix(initial_pheromone);
	initializeHeuristicMatrix();
	initializeProbabiltyMatrix();
	calculateProbabilityMatrix();
	createColony();

	// Iterations loop
	while(!terminationCondition()){
		for(int i=0; i< ants; i++){
			// Construct solution
			colony[i].search();
			// Check for new local optimum
			if(best_tour_length > colony[i].getTourLength()){
				best_tour_length = colony[i].getTourLength();
				best_ant = (Ant) colony[i];
			}
			tours++;
		}
		// Print convergence information (every iteration)
		cout << "* " << tours << " : " << best_ant.getTourLength() << endl;
		evaporatePheromone();   //to implement
		depositPheromone();     //to implement
		calculateProbabilityMatrix(); //to implement
		iterations++;
	}
	// Print the best result found
	cout << "Best " <<  best_ant.getTourLength() << endl;

	freeMemory();   // Free memory.
	cout << "\nEnd of ACO execution.\n" << endl;
}
