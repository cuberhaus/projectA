#include <iostream>
#include <vector>
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

bool is_dominant(const vector<vector<int>>& grafo, const vector<int>& set) {
	bool is = true;
	for (int i = 0; i < grafo.size() && is; ++i) {
	   int size = grafo[i].size();
	   size = ceil(size/2.0);
	   
	   for (int j : grafo[i]) {
		  bool found = false;
		  for (int k : set) if(!found){
			 if (j == k) {
			   --size;
			   found = true;
				 
			 }
		  }
		   
	   }
	   if (size > 0) is = false;  
	   
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
	
	cout << is_dominant(grafo, set) << endl;
	
}
