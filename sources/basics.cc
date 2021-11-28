#include <iostream>
#include <vector>
#include <set>
#include <math.h>

using namespace std;

void readGraph(vector <vector<int>>& adj, const int& e){

	for (int i = 0; i < e; i++)
	{
		int v1,v2;
		cin >> v1 >> v2;
		adj[v1-1].push_back(v2-1);
		adj[v2-1].push_back(v1-1);
	}
}

void printGraph(vector<vector<int>>& adj, const int& n) {
	for (int i = 0; i < n; ++i){
		cout << i+1 << ":";
		int m = adj[i].size();
		for (int j = 0; j < m; ++j){
			cout << " " << adj[i][j]+1;
		}
		cout << endl;
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

bool is_minimal(vector<vector<int>>& adj,const set<int>& set) {
	for (int i = 0; i < set.size(); ++i) {
		int num_edges = adj[i].size();
		bool is_removable = true;
		for (int j = 0; j < num_edges and is_removable; ++j) { // iterem sobre els veins del node que volem "treure" O(D²)
			int neighbour = adj[i][j];
			int num_edges_neigh = adj[neighbour].size();
			int min_dom_neighbours = ceil(num_edges_neigh/2.0);
			int num_dom_neighbours = 0;
			for (int k = 0; k < num_edges_neigh; ++k) { // iterem sobre els veins dels veins del node que volem "treure" O(D²*V)
				if (set.find(adj[neighbour][k]) != set.end()) num_dom_neighbours++; // lg(D)
			}
			if (num_dom_neighbours-1 < min_dom_neighbours) is_removable = false;
		}
		if (is_removable) return false;
	}
	return true;
}

int main () {

	int v, e;
	cin >> v;
	cin >> e;
	vector<vector<int>> adj(v);
	readGraph(adj,v);
	printGraph(adj,v);

	int n;
	cin >> n;
	//vector<int> set(n);
	set<int> set;
	for (int i = 0; i < n; ++i){
		int v1;
		cin >> v1;
		// set.push_back(v1-1);
		set.insert(v1-1);
	}
	bool is_dom = is_dominant(adj,v,set,n);
	cout << "This set is a positive influence dominating set: " << is_dom << endl;
	if (is_dom) cout << "It is minimal: " << is_minimal(adj,set) << endl;
}