# -*- coding: utf-8 -*-
"""
Created on Tue Nov  3 22:38:24 2020

@author: Kyle
"""


"""This file holds supporting functions for the 
rope drag simulator series of files"""


import parameters
import math
import scipy
from scipy.optimize import fsolve
import numpy as np
import re
import datetime
import time


#constants.
friction_eq=parameters.friction_equation
friction_coefficient=parameters.friction_coefficient




#Returns the heading of the rope. 90 is up.
#Directly up is 90 degrees, left is 180, down is 270, etc.
def find_heading(cur_pt, next_pt, slope='linear'):
    cur_x,cur_y,next_x,next_y=cur_pt[0],cur_pt[1],next_pt[0],next_pt[1]
    if slope=='linear':
        #find slope:
        if next_x-cur_x==0: slope=10000     #Avoid divide by zero.
        else: slope=((next_y-cur_y)/(next_x-cur_x))
    #Finding the angle in degrees from the slope.
    ang=math.degrees(math.atan(slope))
    #If slope is positive or zero, and going route is right:
    if (slope >= 0) and (cur_x < next_x): Heading=ang
    #If slope is positive or zero, and route is going left:
    if (slope >= 0) and (cur_x > next_x): Heading=ang+180
    #If negative slope and route is going right:
    if (slope < 0) and (cur_x < next_x): Heading=ang+360
    #If negative slope and route is going left:
    if (slope < 0) and (cur_x > next_x): Heading=ang+180
    #If route is going straight up:
    if cur_x == next_x: Heading = 90
    return Heading
    




#returns deflection angle. 
def find_deflec_angle(head_in, head_out):
    if (abs(head_out-head_in)) > 180:
        dif=(abs(head_out-head_in))
        angle=(abs(head_out-head_in)) - (2*(dif-180))
    else: angle=abs(head_out-head_in)
    return angle





#returns drag after. Could switch equations in the parameters file. 
def find_drag_after(drag_before,deflec_angle):
    if friction_eq=='Experimentally Found Mod':
        Drag_After=(((-10**-5)*((deflec_angle)**2))+(.0095*(deflec_angle))+1)*drag_before;
        #At low loads, the formula underestimates drag a little. Below multiplies by a mod factor to adjust if at low loads. Just linearized factor from 1.2 to 1, for 0-2 lbs. 
        if drag_before < 1:
            mod_factor=1+((1-drag_before)*.6)
            Drag_After=Drag_After*mod_factor
    
    elif friction_eq=='Experimentally Found':
        Drag_After=(((-10**-5)*((deflec_angle)**2))+(.0095*(deflec_angle))+1)*drag_before;
        
    elif friction_eq=='Capstan':
        Drag_After=((drag_before)/(math.exp(-1*friction_coefficient*(math.radians(deflec_angle)))));
        
    elif friction_eq=='Common':
       #The common equation for friction is:
       #(Force of friction) = (Friction coefficient) * (Normal force)
       #Also, (Force of friction) = (Rope drag after) - (Rope drag before)
       #Combining: (Rope drag after) - (Rope drag before) = (Friction coefficient) * (Normal force)
       #The (Normal Force) can be found in terms of (Rope drag before), (Rope drag after), and the
       #angles, with static equalibrium equations. With that, the only unknown in the combined equation
       #above is (Rope drag after) and we can solve.
       #Since we don't care about the direction of the normal force for the equation, only the
       #magnitude, to make the calculation cleaner the (Rope drag after) vector is oriented to be
       #completely in the i direction. The relative angle between the two vectors is still the same doing that.
       
       #a function of x to solve for numerically below. 
       def f(x):
           #i components of the two vectors at the clip. 
           i=((drag_before*np.cos(math.radians(180-deflec_angle))+x))
           #j components of the two vectors at the clip. 
           j=((drag_before*np.sin(math.radians(180-deflec_angle))))
           #Normal force:
           N=((i**2)+(j**2))**.5
           return ((N*friction_coefficient)+drag_before)-x
       Drag_After=fsolve(f,10)  #10 is an initial guess.
       
    elif friction_eq=='Common Modified':
        def f(x):
           i=((drag_before*np.cos(math.radians(180-deflec_angle))+x))
           j=((drag_before*np.sin(math.radians(180-deflec_angle))))
           N=((i**2)+(j**2))**.5
           return ((N*friction_coefficient)+drag_before)-x
        Drag_After=fsolve(f,10)
       
       #At low loads, the formula underestimates drag a little. Below multiplies by a mod factor to
       #adjust if at low loads. Just linearized factor from 1.2 to 1, for 0-2 lbs. 
        if drag_before < 1:
            mod_factor=1+((1-drag_before)*.6)
            Drag_After=Drag_After*mod_factor
        
    elif friction_eq=='Linear':
        #Based on the fact that pulling a 20 lb weight 180 deg over an i-beam construction carabiner
        #required about 44 lbs to move. 20 * 2.2 = 44
        mod_factor=2.2+((drag_before)*-.00666667)
        Drag_After=Drag_After*mod_factor
    else:
        print('You did not enter a valid input for friction equation in the input section.')
        print('Enter "Experimentally Found", "Capstan", "Common", or "Linear"')
    
    return Drag_After






#returns height of plot if user wants to change it. 
def ask_area_height(height):
    ans=input('The plot area is set to {} square meters. Change? (y/n)\n'.format(height))
    while ans!='n' and ans!='y':
        print('Invailid input.')
        ans=input('Go again? (y/n)\n')
    if ans=='y':
        while True:
            try:
                height=int(input('Enter a positive integer for plot height:\n'))
                assert height>0
                break
            except:
               print('That was not  positive integer. Try again.\n')
        return height
    else:
        return height
    
    




def ask_draw_or_enter():
    ans=input('\nDo you want to draw the route or enter points? (draw/enter)\n')
    while ans!='draw' and ans!='enter':
        print('Invailid input.')
        ans=input('\nDo you want to draw the route or enter points? (draw/enter)\n')
    return ans
    


        
    

def ask_for_route():
    ans=input('Enter coordinate points for the bend locations in the form [x1,y1], [x2,y2], [x3,y3]...\n')
    points=convert_input_route_to_list(ans) #Returns False if input is in wrong
    while points==False:
        ans=input('Enter coordinate points for the bend locations in the form [x1,y1], [x2,y2], [x3,y3]...:\n\n')
        points=convert_input_route_to_list(ans)
    return points





#If the user inputs coordinates for a route, convert those to a list of points. 
def convert_input_route_to_list(ans):
    while True:
        try:
            xvals=re.findall('\[([^,]+)', ans, flags=0)
            yvals=re.findall('\[[^,]+,([^\]]+)', ans, flags=0)
            xvals=[float(num) for num in xvals]
            yvals=[float(num) for num in yvals]
            assert len(xvals)!=0
            assert len(xvals)==len(yvals)
            points=[]
            for i in range(0,len(xvals)):
                points.append([xvals[i],yvals[i]])
            return points
        except AssertionError:
            print('\nThere were not the same number of x and y values, or there were no valid values.\n')
            return False
        except:
            print('\nInvailid entry. Please try again. \n')
            return False






def print_results(route):
    print('\n\nRoute:\n')
    print(route.points_unconverted)
    
    print('\n\nRope drag immediatly before bend:\n')
    print('Point Num\tRope Weight\tFriction\tTotal (lbs)\n')
    for i in range(route.num_points):
        string='{}\t\t{}\t\t{}\t\t{}\n'.format(i,
                                        round(float(route.total_rope_weight[i]),2),
                                        round(float(route.total_friction_drag[i]),2),
                                        round(float(route.drag_before[i]),2))
        print(string.expandtabs())

    




def ask_save_data():
    ans=input('\nDo you want to save the data to a txt file? (y/n)\n')
    while ans!='n' and ans!='y':
        print('Invailid input.')
        ans=input('\nDo you want to save the data to a txt file? (y/n)')
    if ans=='n':
        return False
    else:
        return True
    
    
    
    
    
def save_data(route):
    file=str(datetime.date.today())+'-'+str(int(time.time()))+'.txt'
    with open(file, 'w') as file_name:   #Using 'with open' as good practice.
        file_name.write('\n\nRoute:\n')
        file_name.write(str(route.points_unconverted))
        
        file_name.write('\n\nRope drag immediatly before bend:\n')
        file_name.write('Point Num\tRope Weight\tFriction\tTotal (lbs)\n')
        for i in range(route.num_points):
            string='{}\t\t{}\t\t{}\t\t{}\n'.format(i,
                                            round(float(route.total_rope_weight[i]),2),
                                            round(float(route.total_friction_drag[i]),2),
                                            round(float(route.drag_before[i]),2))
            file_name.write(string.expandtabs())    
            
            



#Returns True or False for whether or not the catenary iterations are diverging.
#Takes in a list of drag after approximations during the iteration.  
def diverging(da):
    most_recent_da=abs(da[len(da)-1])
    second_most_recent_da=abs(da[len(da)-2])
    third_most_recent_da=abs(da[len(da)-3])
    most_recent_del=abs(second_most_recent_da-most_recent_da)
    sec_most_recent_del=abs(third_most_recent_da-second_most_recent_da)
    if len(da)<6: return False
    elif most_recent_del>sec_most_recent_del: return True
    else: return False
    
    
    
    
    
#Takes a list of coordinate points. Returns the list with rounded numbers.
def points_rounded(points):
    points_rounded=[]
    for point in points:
        new_point=[]
        for num in point:
            new_point.append(round(num,2))
        points_rounded.append(new_point)
    return points_rounded