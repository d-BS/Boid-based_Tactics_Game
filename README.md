# Small Personal Project I'm working on

## Current features:
	
	The titular boids, using a modified algorithm. 
	
	Simple selection and target setting, basic formation implementaion
	
	Basic grass shader I cooked up


## Known issues:
	
	There are still a few kinks that need to be worked out with the GPU boids
		-  There are a handful that refuse to cooperate, and really want to be nan
		-  Deletion is still unstable
	
	GPU boids use naive O(N^2) implementation, I will get to making that better later
	


## Controls (As of when I am writing this):

	Arrow keys to move the camera, +/- keys to zoom in / out.

	Click + Drag to select units
	Right click to give current selection a goal.
	F to tell current selection to use a formation
	Backspace / Delete to get rid of current selection's goal and formation
	

	Spacebar to reset 

	
