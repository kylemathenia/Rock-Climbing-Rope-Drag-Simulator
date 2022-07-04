
import parameters
import rds_funcs
import numpy as np
import math
from scipy.optimize import fsolve


METER_2_FEET=3.281
FEET_2_METER=0.3048

percent_change=parameters.percent_change
density=parameters.density
path_spacing=parameters.path_spacing

class Route:
    def __init__(self, points):
        points.insert(0,[points[0][0],0])   #add the ground point directly underneath 1st pt.
        self.points=points
        #to avoid conversion errors and display at end.
        self.points_unconverted=rds_funcs.points_rounded(points)
        self.num_points=len(points)
        #x and y values of points stored in lists. 
        self.x_vals=[points[i][0] for i in range(0,len(points))]
        self.y_vals=[points[i][1] for i in range(0,len(points))]
        self.path_x_vals=[]             #x values for path of the rope. 
        self.path_y_vals=[]             #y values for path of the rope.
        self.total_rope_weight=[0]      #at each point.
        self.drag_after=[0]             #drag immediatly after each point.
        self.drag_before=[0]            #drag immediatly before each point.
        self.friction_added=[0]         #friction added at each point.
        self.deflec_angles=[0]          #weight of the segment of rope for each point.
        self.weight_prev_rope_segment=[0]
        self.heading_in=[90, 90]        #heading of the rope going into each point.
        self.heading_out=[90]           #heading of the rope going out of each point.
        self.total_friction_drag=[]     #at each point
        self.droop_to_inf=False
        self.cat_path_point=None        #unused for now
        self.cat_iters_pathx=[]         #unused for now
        self.cat_iters_pathy=[]         #unused for now

    #Resets values 
    def __reset(self):
        self.path_x_vals=[]             #x values for path of the rope. 
        self.path_y_vals=[]             #y values for path of the rope.
        self.total_rope_weight=[0]      #at each point.
        self.drag_after=[0]             #drag immediatly after each point.
        self.drag_before=[0]            #drag immediatly before each point.
        self.friction_added=[0]         #friction added at each point.
        self.deflec_angles=[0]          #weight of the segment of rope for each point.
        self.weight_prev_rope_segment=[0]
        self.heading_in=[90, 90]        #heading of the rope going into each point.
        self.heading_out=[90]           #heading of the rope going out of each point.
        self.total_friction_drag=[]     #at each point
        self.droop_to_inf=False
        self.cat_path_point=None        #unused for now
        self.cat_iters_pathx=[]         #unused for now
        self.cat_iters_pathy=[]         #unused for now

    #Climbers in the US are familiar with lbs and meters... Calculation are done in imperial.
    def __convert_lengths(self,CONVERSION):
        global METER_2_FEET
        #convert points
        for i in range(0,len(self.points)):
            for a in range(2):
                self.points[i][a]=self.points[i][a]*CONVERSION
        #convert path
        self.path_x_vals=[i*CONVERSION for i in self.path_x_vals]
        self.path_y_vals=[i*CONVERSION for i in self.path_y_vals]
        #convert cat paths
        self.cat_iters_pathx=[i*CONVERSION for i in self.cat_iters_pathx]
        self.cat_iters_pathy=[i*CONVERSION for i in self.cat_iters_pathy]
        #conver x_vals
        self.x_vals=[i*CONVERSION for i in self.x_vals]
        #conver y_vals
        self.y_vals=[i*CONVERSION for i in self.y_vals]

    #Linear approximation of rope drag. 
    def linear_approx(self):
        global METER_2_FEET
        global FEET_2_METER
        not_last_point=True
        
        self.__reset()  #reset values in case another method was run before.
        
        #Set the rope path.
        self.path_x_vals=self.x_vals
        self.path_y_vals=self.y_vals
        
        #covert to imperial.
        self.__convert_lengths(METER_2_FEET)
        
        #find values for every point starting at the second point. (not the ground point)
        for i in range(1,self.num_points):
            if i==self.num_points-1: not_last_point=False
            
            #weight of previous rope segment is (change in y's) * (density)
            self.weight_prev_rope_segment.append((self.y_vals[i]-self.y_vals[i-1])*density)
            #drag before is the drag at the last point + weight of the rope segment.
            self.drag_before.append(self.drag_after[i-1]+self.weight_prev_rope_segment[i])
            #find the total rope weight at this point.
            self.total_rope_weight.append(self.y_vals[i]*density)
            if not_last_point:
                #find rope heading out of point.
                head_out=rds_funcs.find_heading(self.points[i],self.points[i+1])
                self.heading_out.append(head_out)
                #heading_in for the next clip will be the current heading out.
                self.heading_in.append(self.heading_out[i])
                #find the deflection angle of the rope at point.
                deflec_angle=rds_funcs.find_deflec_angle(self.heading_in[i],self.heading_out[i])
                self.deflec_angles.append(deflec_angle)
                #find the drag after the bend. 
                drag_after=rds_funcs.find_drag_after(self.drag_before[i],self.deflec_angles[i])
                self.drag_after.append(drag_after)
                #find friction added
                self.friction_added.append(self.drag_after[i]-self.drag_before[i])
        
        
        self.total_friction_drag=[(self.drag_before[i]+self.total_rope_weight[i])- self.drag_before[i]
                                  for i in range(0,self.num_points)]
        self.__convert_lengths(FEET_2_METER)
        return self

    #Catenary approximation of rope drag. 
    #Optional cat_path_point argument if you want to capture the catenary path data from that point to the next. Defaults to None.
    def catenary_approx(self,cat_path_point=None):
        #do the linear approximation first to get initial guesses.
        self.linear_approx()
        #reset path.
        self.path_x_vals=[self.x_vals[0],self.x_vals[0]]
        self.path_y_vals=[0,self.y_vals[0]]
        
        #store the point to exam cat iterations.
        self.cat_path_point=cat_path_point
        
        global METER_2_FEET
        global FEET_2_METER

        #covert to imperial
        self.__convert_lengths(METER_2_FEET)
        
        #For all points except the first and last. 
        for point in range(1,len(self.points)-1):
            self.__find_catenary(point)  #find the values
        
        #store component of drag due to friction for each point. 
        self.total_friction_drag=[(self.drag_before[i]-self.total_rope_weight[i])
                                  for i in range(0,self.num_points)]
        #covert to metric
        self.__convert_lengths(FEET_2_METER)

    #Stores catenary values for a single point on the route. 
    def __find_catenary(self, i):
        xc=self.x_vals[i]      #x value of current point.
        yc=self.y_vals[i]      #y value of current point.
        xn=self.x_vals[i+1]    #x value of next point.
        yn=self.y_vals[i+1]    #y value of next point.
        
        #Difference in x and y from next to current.
        dx,dy=(xn-xc),(yn-yc)
    
        #If the next clip is directly up, and the previous point is directly below.
        if dx==0 and self.x_vals[i-1]==xc:
            self.__no_bend_results(i)
        
        #If the next point is directly up, and the previous point is not directly below. 
        #The deflection angle at the current point changed because the previous segment 
        #follows a catenary curve.
        elif dx==0:
            self.__bend_to_vert_results(i)
        
        #Else, the path will be a catenary.
        else:
            #If path is extremely straight, math gets wild. Use linear approximation.
            stop_iter_use_linear=False
            
            #This list keeps track of all the drag after values as the iteration goes on.
            da=[self.drag_after[i],0.0001]
            
            
            #Find better approximations until the percent change in drag values is sufficiently small.
            #da[len(da)-1] is the most recent drag after value. da[len(da)-2] is the val before that. 
            while ((abs((da[len(da)-2]-da[len(da)-1])/(da[len(da)-2])))*100) > percent_change:
                """Below are the parameters that define the shape of the catenary 
                curve. (Horizontal component of tension, and linear density of rope."""
                #Horizontal component of drag after at the current point.
                da_h=(abs(math.cos(math.radians(self.heading_out[i])))*self.drag_after[i])
                d=density
                #Combining these parameters into a single term. 
                a=da_h/d
                """The shape of the curve is now defined. The problem is that the correct
                position in space to show the path between clips is not known. 
                The curve, without translation, is centered on x=0."""
                
                """To find where the curve should be moved to, points on the curve 
                that are the same distance apart in x and y as our actual clips are
                found. This yields coordinates on the curve that represent our clips.
                These coordinates are then matched in space to our actual clip 
                locations by translating the curve. Outputs are equal for both
                points if the curve for the second point is translated dx and dy."""
                while True:
                    try:
                        #function or x to use with numerical solver below. 
                        def f(x):
                            eq1=(a*math.cosh(x/a))
                            eq2=(a*math.cosh((x+dx)/a))-dy
                            return eq1-eq2  #0=eq1-eq2.
                
                        """Solve the equation for the point on the curve that represents 
                        where the current point is for the non-translated catenary curve."""
                        x1_Catenary=fsolve(f,10)    #10 is an initial guess for the solver. 
                        
                        if rds_funcs.diverging(da): #if iterations are diverging.
                            self.droop_to_inf=i
                            print('\nThe rope drooped to infinity between bend {} and {}. Please try again shorter traversing segments.\n'.format(self.droop_to_inf,self.droop_to_inf+1))
                            raise Exception()                    
                        break
                    except RuntimeWarning:
                        #If the math is getting wild, a linear approximation works. 
                        stop_iter_use_linear=True
                        break
                    except OverflowError:
                        print('\n\nThe math was too extreme to calculate. Try again with shorter segments.\n')
                        break
                    except:
                        raise Exception()
                        break
                
                if stop_iter_use_linear==True:
                    break

                #The representative y value for the current clip is found. 
                y1_Catenary=(a*math.cosh(x1_Catenary/a))
                
                """The differences between the representative current clip 
                coordinates on the curve and the actual current clip coordinate
                are found. These offsets are used to translate the curve when 
                storing the path points below. """
                x_off=(xc-x1_Catenary)
                y_off=(yc-y1_Catenary)
    
                """Just for informational purposes, the equation for the catenary 
                approximation of the path of the rope from the current clip to 
                the next clip is:
                y=a*cosh((x-x_off)/a))+y_off)"""
    

                """With this new path between points, the heading of the rope 
                out of the current clip is different than before. This also 
                means that deflection angle, force of friction, and therefor 
                DFa is different than before. Below we find the new da estimation 
                according to this new heading out of the clip. Then, loop 
                back with the new da to find a new catenary approximation. With
                more iterations the approximation will approach the actual."""
    
                #The derivative of the path equation is:
                #y=sinh((x-x_off)/a))
    
                #Finding slope at current point:
                slope_xc=math.sinh((xc-x_off)/(a))
                
                #find new heading out.
                self.heading_out[i]=rds_funcs.find_heading([xc,yc],[xn,yn],slope_xc)
                #Find new deflection angle. 
                self.deflec_angles[i]=rds_funcs.find_deflec_angle(self.heading_in[i], self.heading_out[i])
                #store new da
                da.append(self.drag_after[i])
                #Find the new drag after approx.
                self.drag_after[i]=rds_funcs.find_drag_after(self.drag_before[i],self.deflec_angles[i])
        
                #if user wants to see that catenary path iterations for this point, store vals.
                if self.cat_path_point==i:
                    x_vals,y_vals=self.__find_cat_path(a,x_off,y_off,xc,xn)
                    self.cat_iters_pathx+=(x_vals)
                    self.cat_iters_pathy+=(y_vals)
                
                
            if stop_iter_use_linear==True:  #store linear approx values.
                self.heading_out[i]=rds_funcs.find_heading(self.points[i],self.points[i+1])
                #find the deflection angle of the rope at point.
                self.deflec_angles[i]=rds_funcs.find_deflec_angle(self.heading_in[i],self.heading_out[i])
                self.drag_after[i]=rds_funcs.find_drag_after(self.drag_before[i],self.deflec_angles[i]) 
                self.friction_added[i]=self.drag_after[i]-self.drag_before[i]
                self.drag_before[i+1]=self.drag_after[i]+self.weight_prev_rope_segment[i+1]
                self.total_rope_weight[i+1]=self.total_rope_weight[i]+self.weight_prev_rope_segment[i+1]
                self.path_x_vals+=[self.points[i][0],self.points[i+1][0]]
                self.path_y_vals+=[self.points[i][1],self.points[i+1][1]]
            else:   #store catenary approx values.
                x_vals,y_vals=self.__find_cat_path(a,x_off,y_off,xc,xn)    
                self.path_x_vals+=(x_vals)
                self.path_y_vals+=(y_vals)
                self.friction_added[i]=self.drag_after[i]-self.drag_before[i]
                slope_xn=math.sinh((xn-x_off)/(a))
                self.heading_in[i+1]=rds_funcs.find_heading([xc,yc],[xn,yn],slope_xn)
                self.drag_before[i+1]=((da_h)/(abs(math.cos(math.radians(self.heading_in[i+1])))))
                self.weight_prev_rope_segment[i+1]=self.drag_before[i+1]-self.drag_after[i]
                self.total_rope_weight[i+1]=self.total_rope_weight[i]+self.weight_prev_rope_segment[i+1]

    #stores approximation values if there is no bend.    
    def __no_bend_results(self,i):
        self.drag_after[i]=self.drag_before[i]
        self.drag_before[i+1]=self.drag_after[i]+self.weight_prev_rope_segment[i+1]
        self.total_rope_weight[i+1]=self.total_rope_weight[i]+self.weight_prev_rope_segment[i+1]
        self.path_x_vals+=[self.x_vals[i],self.x_vals[i+1]]
        self.path_y_vals+=[self.y_vals[i],self.y_vals[i+1]]

    #stores approximation values if the next point is directly above.   
    def __bend_to_vert_results(self,i):
        self.deflec_angles[i]=rds_funcs.find_deflec_angle(self.heading_in[i],self.heading_out[i])
        self.drag_after[i]=rds_funcs.find_drag_after(self.drag_before[i],self.deflec_angles[i])
        self.friction_added[i]=(self.drag_after[i]-self.drag_before[i])
        self.drag_before[i+1]=self.drag_after[i]+self.weight_prev_rope_segment[i+1]
        self.total_rope_weight[i+1]=self.total_rope_weight[i]+self.weight_prev_rope_segment[i+1]
        self.path_x_vals+=[self.x_vals[i],self.x_vals[i+1]]
        self.path_y_vals+=[self.y_vals[i],self.y_vals[i+1]]

    #returns a list of lists for coordinates for the catenary path of the rope. 
    def __find_cat_path(self, a,x_off,y_off,xc,xn):
        """create a vector of x values from from min to max x coords with path spacing"""
        x_path=np.arange(min(xc,xn), max(xc,xn), path_spacing).tolist()
        if xc>xn: #If route goes left, reverse to get right orientation.
            x_path.reverse()
        y_path=[]
        for i in range(0,len(x_path)):
            y_path.append((a*math.cosh((x_path[i]-x_off)/a))+y_off)
        return x_path,y_path
        path=[]
        for x in range(0,len(x_path)):
            path.append([x_path[x],((a*math.cosh((x-x_off)/a))+y_off)])
        return path