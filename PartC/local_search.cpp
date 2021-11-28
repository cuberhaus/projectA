#include <iostream>
#include <vector>
#include <set>
#include <queue>
#include <math.h>
#include "Timer.h"
#include "Random.h"
using namespace std;

vector<vector<int>> adj;
vector<int> dom_neigh;


void read(int e,set<int>& cjt_dom){
    int v1, v2;
    for(int i = 0; i < e ; ++i){
        cin>> v1 >> v2;
        adj[v1-1].push_back(v2-1);
        adj[v2-1].push_back(v1-1);
    }
    for(int i = 0; i < adj.size(); ++i){
        dom_neigh.push_back(adj[i].size());
        cjt_dom.insert(i);
    }
}


void update_neighbours(int node, bool del){
    
    for(int i : adj[node]){
        if(del) --dom_neigh[i];
        else ++dom_neigh[i];
    }
}

bool still_dominant(int node) {
	
	for (int i : adj[node]) {// veinats del que volem eliminar 
        int veins_dominants_act= dom_neigh[i]-1;//li estam llevant un node dominant als seus veinats
        if ((double(veins_dominants_act)) < ceil((adj[i].size())/2.0) ) {
            return false; 
        }
    }

    return true; 
}

void rellena_vec(set<int>&cjt_domin, set<int>&resta, vector<int>&poss_del, vector<int>&poss_add){

    poss_del = vector<int>(0);
    poss_add = vector<int>(0);
    
    for(int i : cjt_domin){   
        if(still_dominant(i)) poss_del.push_back(i);
    } 
    for(int i : resta)poss_add.push_back(i);
    
}

set<int> successor_function(set<int>&cjt_domin,set<int>&resta, bool&del, int& node){
    
    set<int> succesor = cjt_domin;
    vector<int> poss_del,poss_add;
    rellena_vec(cjt_domin,resta,poss_del, poss_add);
    // cout<<"nodes que podem eliminar:";
    // for(int i : poss_del) cout<< i +1 <<" ";
    
    if(poss_del.size()>0){//podem eliminar nodes
        int random = rand() % poss_del.size()-1; // eliminam un node aleatoriament
        // cout<<"Eliminam node "<<poss_del[random] +1 <<endl;
        succesor.erase(poss_del[random]);
        del=true;
        node = poss_del[random];//node que hem eliminat
    }
    else { 
        
        int random = rand() % poss_add.size()-1; //afegim un node aleatoriament
        succesor.insert(poss_add[random]);
        del=false;
        node= poss_add[random];//node que hem afegit
    }
    
    return succesor;
}


int valor(vector<bool>&d){ // retornam el valor d'una possible solucio, el valor es el numero de vertexs que esteim agafant, voldrem reduir aquest nombre
    int x = 0;
    for(bool i : d)
        if(i) ++x;
    return x;
}



void print_set(set<int>&s){
    for(int i : s) cout<< i+1<<" ";
    cout<<endl;
}

double new_temperatura (double tempactual, double k, double lambda) {
    return (k * (pow(exp(1.0), (-lambda)*(tempactual)*1.0))  ); 
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



int main(){
    int v;
    int e;
    
    cin>>v>>e;
    set<int> cjt_dom;
    set<int> resta;
    adj.resize(v);
    read(e,cjt_dom);
    
    Timer timer;
    cout<<"INICIAM CERCA LOCAL"<<endl;
    //==============================================================================================================================
    //INICIAM LA CERCA LOCAL 
    int iteracions = 1000;
    int itpertemp= 1;
    double k = 0;
    double lambda= 0.0000000001;

    int it_act = 0;
    double temperatura = v; //tempertura inicial = num vertexs   

    for(int i = 0; i < iteracions; ++i){
        
        if(it_act == itpertemp){
            it_act = 0;
            temperatura = new_temperatura(temperatura, k , lambda);
        }
        bool del=false;
        int node=0;
        
        set<int> succesor = successor_function(cjt_dom,resta,del,node);
        
            int diff = cjt_dom.size() - succesor.size();
        
            if( diff > 0 ){ // hem eliminat un node
                
                if(del){
                    // cout<<"Hem eliminat el node "<<node+1<<endl;
                    cjt_dom.erase(node);
                    resta.insert(node);
                    
                }
                
                else {
                    cjt_dom.insert(node);
                    resta.erase(node);
                    
                }
                update_neighbours(node,del);
                
            }

            else { // hem afegit un o cap nodes

                double prob = pow(exp(1.0), (diff) / (temperatura * 1.0) );
                if(rand() % 1000 < int(prob * 1000)) {
                    if(del){
                        // cout<<"Hem eliminat el node "<<node+1<<endl;
                        cjt_dom.erase(node);
                        resta.insert(node);     
                    }
                    
                    else {
                        cjt_dom.insert(node);
                        resta.erase(node);
                    }
                    update_neighbours(node,del);
                }
            }
     
        
       
        ++it_act;
    }
   
    
    print_set(cjt_dom);
    cout<<endl;
    cout<<(cjt_dom.size())<<endl;
    cout<<endl;
    cout<<timer.elapsed_time(Timer::VIRTUAL)<<endl; 

}