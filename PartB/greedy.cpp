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
#include <queue>

// global variables concerning the random number generator (in case needed)
time_t t;
Random* rnd;

// Data structures for the problem data
int n_of_nodes;
int n_of_arcs;
vector< set<int> > neighbors;
vector< int > OrdenadoToOriginal; // dado un indice ordenado obtienes el indice original
vector< int > OriginalToOrdenado; // dado un indice original obtienes el indice ordenado

// value solution parameter
vector< set<int> > solutionSet;
vector< vector<int> > solutionVector;
int solution;

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

vector< vector<int> > parseSetToVector(const vector< set<int> >& S) {
    vector< vector<int> > vec = vector< vector<int> >(n_of_nodes);
    for (int i = 0; i < S.size(); i++) {
        vector<int> innerVec = vector<int>(S[i].size());
        int j = 0;
        for (auto x : S[i]){
            innerVec[j] = x;
            j++;
        }
        vec[i] = innerVec;
    }
    return vec;
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

int hS(const int& deg, const int& index, const vector< set<int> >& S) {
    int deghalf = ceil((float)deg/(float)2); 
    int nS = neighborsOfIn(index, S);
    return deghalf - nS;
}

int coverDegree(const int& i, const vector< set<int> >& V, const vector< set<int> >& S) {
    // cover-degree(v) = |{ u ∈ N(v) : hS(u) > 0}|
    // i = nodo del grafo === indice en el vector entiendo que V
    // V y S son vectores ordenados por grado entonces 
    int maxIndex = -1;
    int maxValue = -1;
    
    for (auto it = V[i].end(); true; it--) {
        int num = 0;
        // u es aresta a nodo desde V[i]
        // necesito el grado que tiene el nodo u
        int u = *it; 
        int p = hS(neighbors[u].size(),OriginalToOrdenado[u],S);
        if (p > 0) {
            num += 1;
        }
        if (maxValue < num) {
            maxIndex = u;
        }
        if (it == V[i].begin())
            break;
    }


    for (auto u: V[i]) {
        int num = 0;
        // u es aresta a nodo desde V[i]
        // necesito el grado que tiene el nodo u 
        int p = hS(neighbors[u].size(),OriginalToOrdenado[u],S);
        if (p > 0) {
            num += 1;
        }
        if (maxValue < num) {
            maxIndex = u;
        }
    }
    return maxIndex;
}

void eraseVertices(const int& i, const set<int>& u, vector< set<int> >& S) {
    set<int> tmp;
    for (auto x: S[i]) {
        if (u.find(x) == u.end()) // si no encuentro el vertice x en u entonces no lo tengo que borrar
            tmp.insert(x);
    }
    S[i] = tmp;
}

void printNeighborsOf(const vector< set<int> >& V, string name, bool ordered) {
    cout << ""<< endl;
    for (int i = 0; i < V.size(); i++) {
        cout << name << " - N of ";
        if (ordered)
            cout << OrdenadoToOriginal[i]+1 << ": ";
        else
            cout << i+1 << ": ";
        for (auto x : V[i]) 
            cout << x+1 << " ";
        cout << endl;
    }
}

vector< set<int> > greedyHeuristic() {
    // Pan's greedy algorithm
    vector< set<int> > V = vector< set<int> >(n_of_nodes); // neighbors in ascending order of the degree
    vector< set<int> > S = vector< set<int> >(n_of_nodes); // S conjunt buit
    vector< set<int> > S_barret = vector< set<int> >(n_of_nodes); // S barret conjunt del que son a V(neighbours) i no a S
    OrdenadoToOriginal = vector< int >(n_of_nodes,-1);
    OriginalToOrdenado = vector< int >(n_of_nodes,-1);
    vector< int > marcat = vector< int >(n_of_nodes,-1);

    for (int i = 0; i < neighbors.size(); i++) { // Copy V <- neighbors
        V[i] = neighbors[i];
    }

    sort(V.begin(),V.end(),ascendingDegree); // ordenar V

    for (int i = 0; i < V.size(); i++) { // Copy S_barret <- V
        for (int j = 0; j < neighbors.size(); j++) {
            if (V[i] == neighbors[j] && OrdenadoToOriginal[i] == -1 && marcat[j] == -1) {
                OrdenadoToOriginal[i] = j;
                OriginalToOrdenado[j] = i;
                marcat[j] = 0;
                continue;
            }
        }
        S_barret[i] = V[i];
    }

    //printNeighborsOf(V,"Ordered By Degree", true);
    cout << "starting greedy..." << endl;
    set<int> dom;
    set<pair<int,int>> arestes;
    // dom conte al final tots els vertex que pertañen a un conjunt dominant pero amb vertex innecesaris
    for (int i = V.size()-1; i >= 0; i--) {
    //for (int i = 0; i < V.size(); i++) {
        if (!V[i].empty()) {
            dom.insert(OrdenadoToOriginal[i]);
            for(auto x: V[i]) {
                pair<int,int> p(min(OrdenadoToOriginal[i],x),max(OrdenadoToOriginal[i],x));
                arestes.insert(p);
                S_barret[OriginalToOrdenado[x]].erase(OrdenadoToOriginal[i]);
            }
        }
        if (arestes.size() >= n_of_arcs && dom.size() > V.size()/2) break;
    }
    solution = dom.size();

    // Greedy Pan's pero no funciona
    /*for (int i = 0; i < V.size(); i++) {
        int p = hS(V[i].size(), OriginalToOrdenado[i], S);
        if (p > 0) {
            // for j = 1 to ρ do
            for (int j = 0; j < p; j++) {
                int u = coverDegree(i,V, S_barret); 
                if (u >= 0)  {
                    S[u] = neighbors[u];
                }
                eraseVertices(i,neighbors[u],S_barret); // V\S
            } 
        }
    }*/
    //printNeighborsOf(S_barret,"S_barret",true);
    //printNeighborsOf(S,"Solution",false);
   //cout << endl;

    return S;
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

    //printNeighborsOf(neighbors,"Origin",false);

    // Example for requesting the elapsed computation time at any moment: 
    double ct = timer.elapsed_time(Timer::VIRTUAL);

    // HERE GOES YOUR GREEDY HEURISTIC
    // When finished with generating a solution, first take the computation 
    // time as explained above. Say you store it in variable ct.
    solutionSet = greedyHeuristic();

    double ctend = timer.elapsed_time(Timer::VIRTUAL);

    // Then write the following to the screen: 
    cout << "value " << solution << "\ttime " << ctend-ct << endl;
    
}

