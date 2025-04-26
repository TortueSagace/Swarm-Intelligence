/*
 * ant.h
 *
 *  Created on: Mar 22, 2019
 *      Author: christian
 */

#ifndef SRC_ANT_H_
#define SRC_ANT_H_

#include "tsp.h"

class Ant{

	bool init;
	long * seed;
	long int * tour;		/* solution for the TSP */
	bool * visited;			/* auxiliary array for construction to keep track of visited cities */
	long int tour_length;

	double * selection_prob;  /* auxiliary array for selecting the next node */
	double ** probability;    /* combined value of pheromone and  heuristic information */
	TSP * tsp;
	long int size;

	void computeTourLength(); //to implement
	void clearTour();
	long int getNextCity(long int i);
	long int getBestCity(long int i);

public:
	Ant();
	Ant(TSP* tsp_arg, double ** prob_info, long int * seed);
	~Ant();
	Ant(const Ant& other);
	Ant& operator= (const Ant& other);

	void search(); //to implement
	long int getTourLength();
	long int getCity(long int i);
	void printTour();
	void checkTour();
};

#endif /* SRC_ANT_H_ */
