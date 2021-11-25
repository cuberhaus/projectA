#include <iostream>
#include <vector>
#include <set>
#include <math.h>

using namespace std;

void leer_grafo(vector<vector<int>>& grafo, const int& n) {
	
	
	for (int i = 0; i < n; ++i) {
		int vecino;
		int node;
		cin >> node;
		node -= 1;
		while (cin >> vecino and vecino != -1) {
			  grafo[node].push_back(vecino);		
		}
		
	}

}

void escribir_grafo(const vector<vector<int>>& grafo) {
	for (int i = 0; i < grafo.size(); ++i) {
	   cout << i+1 << ":";
	   for (int j : grafo[i]) {
	   		cout << " " << j; 
		}
	   cout << endl;
	}
}

bool is_minimal(const vector<vector<int>>& grafo, const vector<int>& set) {
	bool is = true;
	
	
	
	for (int i = 0; i < set.size(); ++i) if(is){
	bool out = true;
	int aux = i; // guardamos el valor de vertice que vamos a quitar
	   for (int j : grafo[i-1]) if (out) { // iteramos por vecinos de valor del set
	   int size = grafo[j-1].size();
	   size = ceil(size/2.0);
	   
	   for (int k : grafo[j-1]) { //iteramos por el vecino
		  for (int l = 0; l < set.size(); ++l) { // iteramos por los vecinos del vecino
			 if (k == set[l] && l != aux) --size; 
		  }
	   }
	   if (size > 0) out = false;
	}	
	if (out) is = false;
	}
	
	return is;
	
}

bool is_dominant(const vector<vector<int>>& grafo, const vector<int>& set) {
	bool is = true;
	for (int i = 0; i < grafo.size() && is; ++i) {
	   int size = grafo[i].size();
	   size = ceil((size/2.0));
	   
	   for (int j : grafo[i]) {
		  bool found = false;
		  for (int k : set) if(!found){
			 if (j == k) {
			   --size;
			   found = true;
				 
			 }
		  }
		   
	   }
	   if (size > 0) {
		   is = false;  
	   
	   }
	}
	return is;
}

int main() {
	int n, m;
	cin >> n >> m;
	
	vector<vector<int>> grafo(n);
	leer_grafo(grafo, n);
	escribir_grafo(grafo);
	vector<int> set;
	int vertex;
	
	while (cin >> vertex and vertex != -1) {
	     set.push_back(vertex);
	}
	
	if (is_dominant(grafo, set) ) {
	  cout << "Dominant: True" << endl;
	  if (is_minimal(grafo, set)) cout << "Minimal: True" << endl;
	  else cout << "Minimal: False" << endl;
	} else cout << "Dominant: False" << endl;
	
	
	
// 	cout << " I am ceiling: "  << ceil((3/2.0)); 
	
}
