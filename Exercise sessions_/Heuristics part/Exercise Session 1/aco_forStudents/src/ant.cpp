/*
 * ant.cpp
 *
 *  Created on: Feb 15, 2020
 *      Author: Christian Camacho
 */

#include <stdlib.h>
#include <iostream>
#include <math.h>
#include <limits.h>
#include <string.h>

#include "tsp.h"
#include "ant.h"

#define IA 16807
#define IM 2147483647
#define AM (1.0/IM)
#define IQ 127773
#define IR 2836

using namespace std;

/* Default constructor*/
Ant::Ant(){
	seed = 0;
	size = 0;
	tsp  = 0;
	probability = 0;
	selection_prob = 0;
	tour = 0;
	visited = 0;
	tour_length = LONG_MAX;
	init = false;
}

/* Constructor*/
Ant::Ant (TSP* tsp_arg, double ** prob_info, long* pseed){
	seed = pseed;
	size = tsp_arg->getSize();
	tsp  = tsp_arg;
	probability = prob_info;
	selection_prob = new double[size];
	tour = new long int[size];
	visited = new bool[size];
	tour_length = LONG_MAX;
	init = true;
}

/* Copy constructor*/
Ant::Ant (Ant const& other){
	seed = other.seed;
	size = other.size;
	tsp  = other.tsp;
	probability = other.probability;
	selection_prob = new double[size];
	tour = new long int[size];
	visited = new bool[size];
	for(int i=0; i<size ; i++){
		tour[i] = other.tour[i];
		visited[i] = other.visited[i];
		selection_prob[i] = other.selection_prob[i];
	}
	tour_length = other.tour_length;
	init=true;

}

Ant::~Ant (){
	if(init) {
		delete[] tour;
		delete[] visited;
		delete[] selection_prob;
	}
	init=false;
}

Ant& Ant::operator= (const Ant& other) {
	seed = other.seed;
	size = other.size;
	tsp  = other.tsp;
	probability = other.probability;
	selection_prob = new double[size];
	tour = new long int[size];
	visited = new bool[size];
	for(int i=0; i<size ; i++){
		tour[i] = other.tour[i];
		visited[i] = other.visited[i];
		selection_prob[i] = other.selection_prob[i];
	}
	tour_length = other.tour_length;
	init=true;
	return *this;
}

double ran01( long *idum ) {
	/*
      FUNCTION:      rand01
      INPUT:         a pointer to the seed variable
      OUTPUT:        a pseudo-random number uniformly distributed in [0,1]
      Notes:         call this function using ran01(&seed)
	 */
	long k;
	double ans;

	k = (*idum)/IQ;
	*idum = IA * (*idum - k * IQ) - IR * k;
	if (*idum < 0 ) *idum += IM;
	ans = AM * (*idum);
	return ans;
}

/*** EXERCISE 1 starts here ***/

/* Construct a tour applying the stochastic solution construction mechanism */
void Ant::search() {
}

/* Clean the structures used in the previous iteration
 * by the ants to construct a new tour */
void Ant::clearTour() {
}

/* Obtain the next city to visit after city i,
 * using the random proportional rule */
long int Ant::getNextCity(long int i) {
	return 0;
}

/* Compute the length of the tour
 * For the TSP, tours start and end in the SAME city*/
void Ant::computeTourLength() {
}

/*** EXERCISE 1 ends here ***/

long int Ant::getTourLength(){
	return(tour_length); //After a tour in completed this value is recomputed for every ant
}

/*Get the next city to visit greedily*/
long int Ant::getBestCity(long int i) {
	long int j, selected=-1;
	long int best_distance=LONG_MAX;

	for (j=0; j< size; j++){
		if (!visited[j] && i!=j) {
			if (best_distance > tsp->getDistance(i, j)){
				//Get the city with shortest distance
				best_distance = tsp->getDistance(i, j);
				selected =j;
			}
		}
	}
	return(selected);
}

/*Get the city in position i of the tour*/
long int Ant::getCity(long int i) {
	return(tour[i]);
}

void Ant::printTour() {
	for (long int i=0; i < size; i++) {
		printf("%ld - ", tour[i]);
	}
	printf("%ld Total cost: %ld \n", tour[0], tour_length);

}

/* Check if the tour is valid */
void Ant::checkTour() {
	long int aux;
	for (long int i =0; i< size ; i++) {
		aux = tour[i];
		if (tour[i]>= size) cout << "Error: city " << i <<"has a bigger index than number of cities: " << aux << "endl";
		if (tour[i]< 0) cout << "Error: city " << i <<"has a negative index: " << aux << "endl";
		for (long int j=i+1; j<size; j++) {
			if (tour[i]==tour[j]) cout << "Error: city " << i <<"has same index than city "<< j << ": " << aux << "endl";
		}
	}
}
