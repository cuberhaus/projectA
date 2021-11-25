/***************************************************************************
    greedy.cpp 
    (C) 2021 by C. Blum & M. Blesa
    
 ***************************************************************************/

/***************************************************************************
 *                                                                         *
 *   This program is free software; you can redistribute it and/or modify  *
 *   it under the terms of the GNU General Public License as published by  *
 *   the Free Software Foundation; either version 2 of the License, or     *
 *   (at your option) any later version.                                   *
 *                                                                         *
 ***************************************************************************/

#ifdef HAVE_CONFIG_H
#include <config.h>
#endif

#include "Timer.h"
#include "Random.h"
#include <vector>
#include <string>
#include <stdio.h>
#include <stdlib.h>
#include <iostream>
#include <string.h>
#include <fstream>
#include <sstream>
#include <cmath>
#include <cstdlib>
#include <cstring>
#include <sstream>
#include <vector>
#include <set>
#include <limits>
#include <iomanip>

// global variables concerning the random number generator (in case needed)
time_t t;
Random* rnd;

// Data structures for the problem data
int n_of_nodes;
int n_of_arcs;
vector< set<int> > neighbors;

// value solution parameter
float solution;

// string for keeping the name of the input file
string inputFile;

// dummy parameters as examples for creating command line parameters 
// see function read_parameters(...)
int dummy_integer_parameter = 0;
int dummy_double_parameter = 0.0;


inline int stoi(string &s) {

  return atoi(s.c_str());
}

inline double stof(string &s) {

  return atof(s.c_str());
}

void read_parameters(int argc, char **argv) {

    int iarg = 1;

    while (iarg < argc) {
        if (strcmp(argv[iarg],"-i")==0) inputFile = argv[++iarg];
        
        // example for creating a command line parameter param1 
        //-> integer value is stored in dummy_integer_parameter
        else if (strcmp(argv[iarg],"-param1")==0) 
            dummy_integer_parameter = atoi(argv[++iarg]); 
            
        // example for creating a command line parameter param2 
        //-> double value is stored in dummy_double_parameter
        else if (strcmp(argv[iarg],"-param2")==0) 
            dummy_double_parameter = atof(argv[++iarg]);  
            
        iarg++;
    }
}

bool is_dominant(vector<vector<int>>& adj,const int& v, const set<int>& set, const int& n) {
	
	for (int i = 0; i < v; ++i){
		int num_edges = adj[i].size();
		int num_dom_neighbours = 0;
		int min_dom_neighbours = ceil(num_edges/2.0);
		for (int j = 0; j < num_edges; ++j){ // Iterem sobre els veins de cada vèrtex.
			if (set.find(adj[i][j]) != set.end()) num_dom_neighbours++; // Contem quants veins pertanyen al conjunt dominador.
		}
		if (num_dom_neighbours < min_dom_neighbours) return false;
	}
	return true;
}

bool is_minimal(vector<vector<int>>& adj, const int& v, const set<int>& set, const int& n) {
	for (int i = 0; i < v; ++i) {
		int num_edges = adj[i].size();
		bool is_removable = true;
		for (int j = 0; j < num_edges and is_removable; ++j) { // iterem sobre els veins del node que volem "treure"
			int neighbour = adj[i][j];
			int num_edges_neigh = adj[neighbour].size();
			int min_dom_neighbours = ceil(num_edges_neigh/2.0);
			int num_dom_neighbours = 0;
			for (int k = 0; k < num_edges_neigh; ++k) { // iterem sobre els veins dels veins del node que volem "treure"
				if (set.find(adj[neighbour][k]) != set.end()) num_dom_neighbours++; // lg(n)
			}
			if (num_dom_neighbours-1 < min_dom_neighbours) is_removable = false;
		}
		if (is_removable) return false;
	}
	return true;
}

bool ascendingDegree(set<int> s1, set<int> s2) {
    return (s1.size() < s2.size());
}

int neighborsOfIn(const int& index, const vector< set<int> >& S) {
    int sum = 0;
    for (int i = 0; i < S.size(); i++) {
        for (auto x : S[i])
            if(x == index)
                sum += 1;
    }
    return sum;
}

int hS(const set<int>& v, const int& index, const vector< set<int> >& S) {
    int deghalf = ceil((float)v.size()/(float)2); 
    int nS = neighborsOfIn(index, S);
    return deghalf - nS;
}

void coverDegree(const set<int>& v, const int& index, const vector< set<int> >& S) {
    int cont = 0;
    //for (int i = 0; i < V.size(); i++) {
      //  if (hS(V[i], i, S) > 0)
    //}
}

void greedyHeuristic() {
    // Pan's greedy algorithm
    vector< set<int> > V = vector< set<int> >(n_of_nodes); // neighbors in ascending order of the degree
    vector< set<int> > S = vector< set<int> >(n_of_nodes); // S conjunt buit
    vector< set<int> > S_barret = vector< set<int> >(n_of_nodes); // S barret conjunt del que son a V(neighbours) i no a S

    for (int i = 0; i < neighbors.size(); i++) { // Copy V <- neighbors
        V[i] = neighbors[i];
    }

    sort(V.begin(),V.end(),ascendingDegree); // Lo he de ordenar?? En el pseudo codigo sale que sí pero luego pierdo los indices :(

    for (int i = 0; i < V.size(); i++) { // Copy S_barret <- V
        S_barret[i] = V[i];
    }

    for (int i = 0; i < V.size(); i++) {
        cout << "V of " << i+1 << ": ";
        for (auto x : V[i])
            cout << x+1 << " ";
        cout << endl;
    }

    for (int i = 0; i < V.size(); i++) {
        int p = hS(V[i], i, S);
        if (p > 0) {
            for (int j = 0; j < p; j++) {
                /* Aquesta es la part que no se com fer
                    std::set<int>::iterator it = V[i].begin();
                    std::advance(it, j);
                    cout << "u: ";
                    set<int> u = V[*it]; // u* <- argmax{cover-degree(u)|u c Ns_barret(V[i])}
                    for (auto x : u)
                        cout << x+1 << " ";
                    S.push_back(u);
                    S_barret.erase(i); //indice de u puede ser la i probablemente // Supongo que se puede hacer así lo de S_barret <- V\S
                */
            }
            
            //cout << endl;
        }
    }
    solution = 53180.08;
    //return S;
}


/************
Main function
*************/

int main( int argc, char **argv ) {

    read_parameters(argc,argv);
    
    // setting the output format for doubles to 2 decimals after the comma
    std::cout << std::setprecision(2) << std::fixed;

    // initializing the random number generator. 
    // A random number in (0,1) is obtained with: double rnum = rnd->next();
    rnd = new Random((unsigned) time(&t));
    rnd->next();

    // variables for storing the result and the computation time 
    // obtained by the greedy heuristic
    double results = std::numeric_limits<int>::max();
    double time = 0.0;

    // opening the corresponding input file and reading the problem data
    ifstream indata;
    indata.open(inputFile.c_str());
    if(not indata) { // file couldn't be opened
        cout << "Error: file could not be opened" << endl;
    }

    indata >> n_of_nodes;
    indata >> n_of_arcs;
    neighbors = vector< set<int> >(n_of_nodes);
    int u, v;
    while(indata >> u >> v) {
        neighbors[u - 1].insert(v - 1);
        neighbors[v - 1].insert(u - 1);
    }
    indata.close();

    // the computation time starts now
    Timer timer;

    for (int i = 0; i < neighbors.size(); i++) {
        cout << "neighbors of " << i+1 << ": ";
        for (auto x : neighbors[i])
            cout << x+1 << " ";
        cout << endl;
    }

    // Example for requesting the elapsed computation time at any moment: 
    double ct = timer.elapsed_time(Timer::VIRTUAL);

    // HERE GOES YOUR GREEDY HEURISTIC
    // When finished with generating a solution, first take the computation 
    // time as explained above. Say you store it in variable ct.
    greedyHeuristic();

    // Then write the following to the screen: 
    cout << "value " << solution << "\ttime " << ct << endl;
    
}

