/**
 * Written by Carl Molnar
 * On November 3, 2016
 * CSCI 415 Assignment 2
 */

#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include "readfile.h"
#include <string.h>
#include <cuda_runtime.h>
#include <time.h>

using namespace std;

__device__ float
threadCalc(int *inputArr, int threadStartLoc, int lengthArr, int threadStartNode)
{
	int connections[4009];					//The array containing all connections to current node
   	float localSum = 0;					//The local sum from this node
  	int numConnections = 0;					//The counter of the number of connections on this node
  	int threadEndLoc = threadStartLoc + lengthArr;		//The end location of the thread in the input array

   	for(int i = threadStartLoc; i < threadEndLoc; i++){	//From the start of this node to the end,
       		if(inputArr[i] == 1){				//if this node has a connection in the input array,
        		connections[numConnections] = i;	//put it in the connections array
        		numConnections++;			//and increment the number of connections counter
       		}
       	}

   	int threadId = threadStartNode * lengthArr;		//The position of the thread in the input array
        int edges = 0;						//Counter for the number of edges
        int edgeTest1, edgeTest2, edgeCompare1, edgeCompare2;	//The variables for connections to compare

       	for(int i = 0; i < numConnections - 1; i++){						//From the start of this node's connections to the end, for the first connection,
           	for(int j = i + 1; j < numConnections; j++){					//From the start of this node's connections to the end, for the second connection,
                	edgeTest1 = connections[i] - threadId;					//Adjust each node for the position in the input array,
                	edgeTest2 = connections[j] - threadId;

                	edgeCompare1 = (edgeTest1 * lengthArr) + edgeTest2;			//And test both sides of the array for an edge
                	edgeCompare2 = (edgeTest2 * lengthArr) + edgeTest1;

              		if (inputArr[edgeCompare1] == 1 && inputArr[edgeCompare2] == 1)		//If there is an edge,
                	edges++;								//Increment the counter
        	}
        }

        if(numConnections < 2)								//If there are only two connections,
        	localSum = 0;								//These edges don't count
        else										//Otherwise,
	localSum = (float)(2 * edges) / (numConnections * (numConnections - 1));	//Do the calculation

        return localSum;								//And return the local sum
}

__global__ void kernelCalcCoeff( int *inputArr, int lengthArr,int threadPart, float *outputArr){

  	int threadStartLoc = threadIdx.x * lengthArr * threadPart; 	//The start location of the thread in the input array
	int threadStartNode = threadPart * threadIdx.x;			//The start location of the thread in the output array 
  	int threadEndNode = threadStartNode + threadPart;		//The end location of the thread in the output array
        __shared__ float localArr[4009];				//The output array with each node's number of edges
        float localSum;
	int i = 0;

  	if(i < lengthArr){										//If the first node is less than the length of the array, then
   		for(i = threadStartNode; i < threadEndNode; i++){    					//until we reach the last node the thread uses,
    			localSum = threadCalc(inputArr, threadStartLoc, lengthArr, i);			//get a local sum from the thread's current node
	 		outputArr[i] = localSum;							//and store it in the output array,
         		threadStartLoc += lengthArr;							//and then increment to the next node
  		}
	}
	outputArr = localArr;		//Assign the output array to the local array
}

int main(int argc, char **argv)
{
	readfile();
	int length = getNumNodes();

	size_t sizeSum = length * sizeof(float);
	float *h_S = (float *) malloc(sizeSum);

	int numElements = length * length;
	size_t sizeArray = numElements * sizeof(int);

	int *h_A = (int*) malloc(sizeArray);
	double Sum = 0.0;

	clock_t t1,t2;
   	h_A = getMatrix();

	cudaError_t err = cudaSuccess;

  	int  *d_A = NULL;
  	float *d_S = NULL;

   	int nBlocks = atoi(argv[1]);
   	int nThreads = atoi(argv[2]);
   	int partition = length/nThreads;

	//Allocate device memory for the input array
  	err = cudaMalloc((int **)&d_A, sizeArray);
  	if (err != cudaSuccess)
  	{
      		fprintf(stderr, "Failed to allocate device mat A (error code %s)!\n", cudaGetErrorString(err));
      		exit(EXIT_FAILURE);
  	}

	//Allocate device memory for the output array
  	err = cudaMalloc((float **)&d_S, sizeSum);
  	if (err != cudaSuccess)
  	{
      		fprintf(stderr, "Failed to allocate device mat A (error code %s)!\n", cudaGetErrorString(err));
      		exit(EXIT_FAILURE);
  	}

	//Copy the host result array to the device
 	err = cudaMemcpy(d_S, h_S, sizeSum, cudaMemcpyHostToDevice);
  	if (err != cudaSuccess)
  	{
    		fprintf(stderr, "Failed to copy d_S from host to device (error code %s)!\n", cudaGetErrorString(err));
      		exit(EXIT_FAILURE);
  	}

	//Copy the host input array to the device
  	err = cudaMemcpy(d_A, h_A, sizeArray, cudaMemcpyHostToDevice);
  	if (err != cudaSuccess)
  	{
    		fprintf(stderr, "Failed to copy mat A 1 from host to device (error code %s)!\n", cudaGetErrorString(err));
      		exit(EXIT_FAILURE);
  	}

	cout<<"Device memory allocated. Starting threads..."<<endl;

	//Start the timer
	t1=clock();
	//Launch the Cuda kernel
	kernelCalcCoeff<<<nBlocks,nThreads>>>(d_A, length, partition, d_S);
 
	//End the timer
	t2=clock();

	cout<<"Threads complete. Finding sum..."<<endl;

	//Copy the device result array to the host
	cudaMemcpy(h_S, d_S, sizeSum, cudaMemcpyDeviceToHost);

	if(err != cudaSuccess)
	{
  		fprintf(stderr,"Failed to copy mat 3 A from device to host(error code %s)!\n",cudaGetErrorString(err));
  		exit(EXIT_FAILURE);
	}

	//Free the device memory
	err = cudaFree(d_A);
	err = cudaFree(d_S);
	
	//Sum up the partial sums of the threads from the output array
	for(int t = 0; t < length; t++){
    		Sum += h_S[t];
  	}

  	printf("=====================================================\n");
  	double finalSum = (Sum/length);
  	cout<<"Clustering coefficient: "<<finalSum<<endl;

	//Free the host memory
  	free(h_A);
  	free(h_S);

	//Reset the device
    	err = cudaDeviceReset();
      	if (err != cudaSuccess)
      	{
          	fprintf(stderr, "Failed to deinitialize the device! error=%s\n", cudaGetErrorString(err));
          	exit(EXIT_FAILURE);
      	}

	//Find the time and print it
       	float timeElapsed = ((float)t2-(float)t1);  
       	float timeInSeconds = timeElapsed / CLOCKS_PER_SEC;
       	cout<<"Time: "<<timeInSeconds<<" seconds"<<endl;

  	return 0;
}
