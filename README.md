# Small Personal Project I'm working on

## Current features:
	
	The titular boids, using a modified algorithm. 
		-  Includes both a CPU and a GPU implementation
	
	Simple selection and target setting
	
	Basic grass shader I cooked up


## Known issues:
	
	There are still a few kinks that need to be worked out with the GPU boids
		-  The number of boids atm is completely hardcoded
	
	GPU boids use naive O(N^2) implementation, I will get to making that better later
	


## Controls (As of when I am writing this):

	Arrow keys to move the camera, +/- keys to zoom in / out.

	Click + Drag to select units, and right click to give currently selected units a goal.
	Backspace / Delete to get rid of currently selected boid's goal

	Spacebar to reset 
