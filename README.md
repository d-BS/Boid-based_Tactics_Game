## Small Personal Project I'm working on

# Current features:
	
	The titular boids, using a modified algorithm. 
		-  Includes both a CPU and a GPU implementation
	
	Simple selection and target setting
	
	Basic grass shader I cooked up


# Known issues:
	
	There are still a few kinks that need to be worked out with the GPU boids
		-  Some boids are faster than others - I like this generally, but I want to tweak it
		-  The first ~ 92 boids act very strange
	
	GPU boids use naive O(N^2) implementation, I will get to making that better later
	
