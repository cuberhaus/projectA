#include <iostream>
#include <vector>
#include <set>
#include <queue>
#include <math.h>
using namespace std;

vector<vector<int>> adj;

void read(int e){
    int v1, v2;
    for(int i = 0; i < e ; ++i){
        cin>> v1 >> v2;
        adj[v1-1].push_back(v2-1);
        adj[v2-1].push_back(v1-1);
    }
}

set<int> retorna_set(vector<bool>&d){
    set<int> s ;
    for(int i = 0; i < d.size(); ++i){
        if(d[i]) s.insert(i);
    }
    return s;
}


bool is_dominant(const set<int>& set) {
	
	for (int i = 0; i < adj.size(); ++i){
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

int valor(vector<bool>&d){ // retornam el valor d'una possible solucio, el valor es el numero de vertexs que esteim agafant, voldrem reduir aquest nombre
    int x = 0;
    for(bool i : d)
        if(i) ++x;
    return x;
}

void cerca_dominant(vector<bool>&d){
    queue <vector<bool>> q;
    q.push(d);
    while(not q.empty()){
        vector<bool> act = q.front();
        q.pop();
        for(int i = 0; i < act.size(); ++i){ //canviam valor de una posicio
            vector<bool> aux = act;
            aux[i] = not aux[i];
            if(is_dominant(retorna_set(aux)) and valor(aux) < valor(d)){
                q.push(aux);
                d = aux;
            }
        }

        for(int i = 0; i < act.size(); ++i){ // realitzam un swap entre dues posicions diferents
            for(int j = 0; j < act.size(); ++j){
                if( i != j) {
                    vector<bool> aux = act;
                    swap(aux[i], aux[j]);
                    if(is_dominant(retorna_set(aux)) and valor(aux) < valor(d)){
                        q.push(aux);
                        d = aux;
                    }
                }
            }
        }
    }
}


void print_set(set<int>&s){
    for(int i : s) cout<< i+1<<" ";
    cout<<endl;
}





int main(){
    int v;
    int e;

    cin>>v>>e;

    adj.resize(v);
    read(e);
    vector<bool> d(v,true); // Vector per saber quins vertexs esteim agafant i quins no, si true -> esteim agafant el vertex
    set<int> y = retorna_set(d);
    print_set(y);
    cerca_dominant(d);
    set<int> x = retorna_set(d);
    print_set(x);
    

}