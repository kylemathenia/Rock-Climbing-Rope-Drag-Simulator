
#*******************************************************************************************
# *****Friction equation:

# Select the equation that calculates friction at the bends. Actual equations can be seen in the
# friction function at the bottom of the script. 


# Choices: 'Experimentally Found', 'Experimentally Found Mod', 'Capstan', 'Common', 'Common
# Modified', or 'Linear'.


# Experimentally Found - based on a rough garage experiment. Doesn't depend on friction coefficient
#                        variable. 
# Experimentally Found Mod - Probably the most accurate. The modification accounts for the higher
#                             than expected friction at low loads. Doesn't depend on friction
#                             coefficient variable.
# Capstan - Capstan equation. 
# Common - Common equation for friction FF=uN.
# Common Mod - Accounts for higher than expected friction at low loads. 
# Linear - linear relation between multiplier of 1 at 0 degrees and multiplier of 2.2 at 180 degrees.  

friction_equation='Experimentally Found Mod'


#*******************************************************************************************
# *****Friction Coefficient:

# I'm sure the friction coefficient depends on a lot of things. The coefficients below most closely
# matched the equations to the experimental data. 

# Common - 0.38
# Capstan - 1

friction_coefficient= .38;


#***************************************************************************************************
#*****Rope Linear Density:

#Linear density of rope based on black diamond 9.9mm standard rope. 
# Density=.064; #kgs/meter
density=.0429; #lbs/ft. Imperial units for script. 


#***************************************************************************************************
#*****Path Resolution

#This is the spacing between x points on the path for the route. The bigger the spacing, the quicker
#the runtime. 0.1 seemed to be reasonable. 

path_spacing=.1; #meters
path_spacing=path_spacing*3.28; #feet


#***************************************************************************************************
#*****Caternary Iteration Criteria
#Enter the percent change of drag calculated between iterations considered accurate enough to stop
#iterating. Specifically, percent change of RDa, or rope drag immediately after the bend. 

#If percent change is larger than 0.001, I found that it starts to be becomre inaccurate, and not
#that much computation time is gained by making it larger usually. And smaller than 0.001 starts to
#increase the computation time a lot for not much accuracy gain.
 
percent_change=.001;
