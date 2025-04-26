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
double  ** probability;   /* combined value of pheromone and  heuristic information */
double  initial_pheromone = 1.0;
double   alpha;
double   beta;
double   rho;
long int ants;
long int seed = -1;


long int max_iterations;
long int iterations=0;
long int max_tours;
long int tours=0;


vector<Ant> colony;		                /* Colony of virtual ants */
Ant best_ant;
long int best_tour_length=LONG_MAX;   /* Shortest tour found so far */

/* Default parameters: set them! */
void setDefaultParameters(){
	alpha=1.0;
	beta=1.0;
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
			<< "  beta: "  << beta << "\n"
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
			<< "   --ants: Number of ants to build every iteration. Default=10.\n"
			<< "   --alpha: Alpha parameter (float). Default=1.\n"
			<< "   --beta: Beta parameter (float). Default=1.\n"
			<< "   --rho: Rho parameter (float). Defaut=0.2.\n"
			<< "   --tours: Maximum number of tours to build (integer). Default=10000.\n"
			<< "   --iterations: Maximum number of iterations to perform (interger). Default:0 (disabled).\n"
			<< "   --seed: Number for the random seed generator.\n"
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
			beta = atof(argv[i+1]);
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

/* Initialize pheromone with an initial value */
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

// Initialize the heuristic information matrix
void initializeHeuristicMatrix () {
	long int size = tsp->getSize();

	heuristic = new double * [size];
	for (int i = 0 ; i < size ; i++ ) {
		heuristic[i] = new double [size];
		for (int j = 0  ; j < size ; j++ ) {
			if (i!=j) {
				// heuristic information for the TSP is 1/distance
				heuristic[i][j] = 1.0 / (double) tsp->getDistance(i,j);
				// symmetric TSP instances; hence phermone[i][j] = pheromone[j][i]
			} else{
				heuristic[i][j] = 0.0;
			}
		}
	}
}

// This procedure initializes the probability matrix, which is the probability of moving from city i
// to city j according to the random proportional rule. It has to be initialized to zero.
void initializeProbabiltyMatrix() {
	long int size = tsp->getSize();

	probability = new double * [size];
	for (int i = 0 ; i < size ; i++ ) {
		probability[i] = new double [size];
		for (int j = 0  ; j < size ; j++ ) {
			probability[i][j] = 0.0;		//set initial probabilities to zero
		}
	}
}

// Calculate probability matrix for the next iteration
void calculateProbabilityMatrix () {
	long int size = tsp->getSize();
	for (int i = 0 ; i < size ; i++ ) {
		probability[i][i] = 0.0;
		for (int j = (i+1)  ; j < size ; j++ ) {
			//this is done after one iteration finishes
			probability[i][j] = pow(pheromone[i][j], alpha) * pow(heuristic[i][j], beta); //numerator in the random proportional rule
			probability[j][i] = probability[i][j];
		}
	}
}

/* Pheromone evaporation */
// (first part of the pheromone update rule)
void evaporatePheromone(){
	long int size = tsp->getSize();
	for (int i =0 ; i < size ; i ++) {
		for (int j=i+1 ; j < size ; j++) {
			//this is done after one iteration finishes
			pheromone[i][j] = (double)(1.0-rho) * pheromone[i][j]; // (1-rho)·tau_ij
			pheromone[j][i] = pheromone[i][j];
		}
	}
}

/* Adds pheromone to the matrix */
// (second part of the pheromone update rule)
//void addPheromone(long int i , long int j, double delta) {
//	pheromone[i][j] = pheromone[i][j] + delta;		// pheromone deposited by the ant (see depositPheromone())
//	pheromone[j][i] = pheromone[j][i] + delta;
//}

// Compute the amount of pheromone to be deposited
void depositPheromone(){
	double delta; //amount of pheromone to be deposited
	long int i; //city i
	long int j; //city j

	for (int m=0; m< ants; m++) {
		//The contribution of each ant is proportional to the length of the tour it has constructed
		delta = 1.0 / (double) colony[m].getTourLength();
		for (int n =1 ; n < tsp->getSize() ; n ++) {
			//for a more clear implementation use: addPheromone(colony[i].getCity(j-1), colony[i].getCity(j), delta);
			i = colony[m].getCity(n-1);
			j = colony[m].getCity(n);
			pheromone[i][j] = pheromone[i][j] + delta;		// pheromone deposited by the ant (see depositPheromone())
			pheromone[j][i] = pheromone[j][i] + delta;

		}
		//for a more clear implementation use: addPheromone(colony[m].getCity(tsp->getSize()-1), colony[m].getCity(0), delta);
		i = colony[m].getCity(tsp->getSize()-1);
		j = colony[m].getCity(0);
		pheromone[i][j] = pheromone[i][j] + delta;		// pheromone deposited by the ant (see depositPheromone())
		pheromone[j][i] = pheromone[j][i] + delta;
	}
}

/* Check termination condition based on iterations or tours.
 * one of the criteria must be active ( =! 0).*/
bool terminationCondition(){
	if (max_tours != 0 && tours >= max_tours)
		return(true);
	if (max_iterations !=0 && iterations >= max_iterations)
		return(true);
	return(false);
}

/*Free memory used*/
void freeMemory(){

	for(int i=0; i < tsp->getSize(); i++) {
		delete[] pheromone[i];
		delete[] heuristic[i];
		delete[] probability[i];
	}
	delete tsp;
	delete[] pheromone;
	delete[] heuristic;
	delete[] probability;
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
