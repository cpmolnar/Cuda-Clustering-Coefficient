#ifndef _READFILE_H_
#define _READFILE_H_

#include <stdio.h>
#include <iostream>
#include <fstream>
#include <vector>
#include <stdlib.h>
#include <math.h>
#include <pthread.h>
#include <semaphore.h>
#include "timer.h"

using namespace std;
int n;

/* The argument now should be a double (not a pointer to a double) */
//#define READIO() {
int *arr;

void printAdjMatrix()
{
    for (int i=0; i<n ; i++)
    {
        for (int j=0; j<n ; j++){
	    int* ptr = &arr[0] + n * i;
            cout<<ptr[j]<<" ";
	}
        cout<<endl;
    }
}

void readfile(){
	std::ifstream myfile("HcNetwork.txt");
	int u,v;
	int maxNode = 0;
	vector<pair<int,int> > allEdges;

	//Open the file and make a vector that pairs the left and right pieces of data, and counts the number of nodes.
	while(myfile >> u >> v)
	{
	  	allEdges.push_back(make_pair(u,v));
	  	if(u > maxNode)
		   	maxNode = u;

		if(v > maxNode)
		   	maxNode = v;
	}

	n = maxNode +1;  //Since nodes starts with 0, we use this as the real number of nodes.
	cout<<"Graph has "<< n <<" nodes"<<endl;
	
	arr = new int[n*n];

	//populate the matrix with 1s at the edges
	for(int i =0; i<allEdges.size() ; i++){
		u = allEdges[i].first;
		v = allEdges[i].second;
		arr[u*n+v] = 1;
		arr[v*n+u] = 1;
	}
}

int getNumNodes(){
	return n;
}

int* getMatrix(){
	 return arr;
}

#endif

