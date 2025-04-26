/*
 * tsp.h
 *
 *  Created on: Feb 15, 2020
 *      Author: Christian Camacho
 */

#ifndef SRC_TSP_H_
#define SRC_TSP_H_

#define LINE_BUF_LEN     100
#define TRACE( x )

struct point {
	double x;
	double y;
};

class TSP {

	FILE *tsp_file;
	char          name[LINE_BUF_LEN];      	       /* name of the instance */
	char          edge_weight_type[LINE_BUF_LEN];  /* selfexplanatory */
	long int      optimum;                /* optimal tour length (if known), otherwise a bound */
	long int      n;                      /* number of cities */
	long int      n_near;                 /* number of nearest neighbors */
	struct point  *nodeptr;               /* array of structs containing coordinates of nodes */
	long int      **distance;	          /* distance matrix: distance[i][j] is the distance between city i und j */

	/* Distance functions*/
	long int     round_distance (long int i, long int j);
	long int     ceil_distance (long int i, long int j);
	long int     geo_distance (long int i, long int j);
	long int     att_distance (long int i, long int j);
	long int **  compute_distances(void);
	long int     compute_distance(long int i, long int j);

	static double dtrunc (double x);

public:
	TSP (const char *tsp_file_name);	//constructor
	~TSP();						        //destructor
	void printDistance(void) ;
	long int getSize();
	long int getDistance(long int i, long int j);

};

#endif /* SRC_TSP_H_ */
