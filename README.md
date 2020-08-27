# Cuda-Clustering-Coefficient
Uses a Cuda clustering coefficient to compute the center of a graph of n nodes.

# Results
Test runs for required threads and various blocks:

| blocks |threads | time (seconds) | 
|--------|--------|----------------|
| 1 | 50 | 0.000630 | 
|2		|500		|0.000602	| 
|2		|1000		|0.000624	| 
|8		|500		|0.000602	| 
|80		|50		|0.000626	| 
|160		|100		|0.000675	| 
|1		|500		|0.000655	| 
|1		|1000		|0.000633	| 
|80		|100		|0.000615	| 
|8		|1000		|0.000623	| 

# Usage
To compile: 	$ make
To run: 	$ ./cdpClustCoeff <number_of_blocks> <number_of_threads>

# Author
Written by Carl Molnar
November 3, 2016
