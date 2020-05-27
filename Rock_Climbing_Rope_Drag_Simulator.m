clearvars

%% Rock Climbing Rope Drag Simulator
% Find rope drag for rock climbing routes on a vertical wall. Outputs total rope drag (lbs), rope
% drag due to friction, rope drag due to rope weight, a visual plot of the route, deflection angles
% of the rope at each bend, and more. Select from several different equations for friction,
% including an experimentally found equation. Assumes no friction from the rope touching rock, and
% zero tension at the belay.


%% Inputs
%Bend locations, friction equation, friction coefficient, rope density, rope path resolution,
%catenary iteration section selection, iteration end criteria

%***************************************************************************************************
%*****Bend Coordinates:

%The first two x coordinates for the clips should be zero because the simulation assumes belayer is
%directly below first clip. If the belayer was not directly under the first clip in reality the
%results would be virtually the same, but the simulation uses this assumption. I use 'clip' and
%'bend' interchangably here. I know that isn't really right. 

%x location at ground and first clip:
g=0;

%Input the x and y coordinates of the clips in meters. Don't change 'g'. Can't go straight down and
%then straight up. Must have the same number x and y coordinates. 

%Typical-ish route:
Clip_Locations_x=[g   g  1  -1  0  2  1];  %Meters 
Clip_Locations_y=[0   4  8  12  18 22 25]; %Meters

%Linked typical-ish pitches:
%Clip_Locations_x=[g   g  1  -1  0  2  1  1  2  0  1  3  2];  %Meters 
%Clip_Locations_y=[0   4  8  12  18 22 25 29 33 37 43 47 50]; %Meters

%Lots of small bends on a 68 m pitch:
%Clip_Locations_x=[g  g  .5 0  .5 0  .5 0  .5 0  .5 0  .5 0  .5 0  .5 0];  %Meters 
%Clip_Locations_y=[0  4  8  12 16 20 24 28 32 36 40 44 48 52 56 60 64 68]; %Meters

%Lots of medium bends on a 68 m pitch:
%Clip_Locations_x=[g  g  1  0  1  0  1  0  1  0  1  0  1  0  1  0  1  0];  %Meters 
%Clip_Locations_y=[0  4  8  12 16 20 24 28 32 36 40 44 48 52 56 60 64 68]; %Meters

%Z-clip low:  
%Clip_Locations_x=[g   g  1  1  1  1  1];  %Meters 
%Clip_Locations_y=[0   8  4  12  16 20 24]; %Meters

%Z-clip high:  
%Clip_Locations_x=[g   g  0  0  0  1  1];  %Meters 
%Clip_Locations_y=[0   4  8  12  20 16 24]; %Meters

%Z-clip low typical route:  
%Clip_Locations_x=[g   g  1  0  0  2  1];  %Meters 
%Clip_Locations_y=[0   8  4  12  16 20 24]; %Meters

%Z-clip high typical route:  
%Clip_Locations_x=[g   g  2  1  1  0  1];  %Meters 
%Clip_Locations_y=[0   4  8  12  20 16 24]; %Meters

%Zig zag low:
%Clip_Locations_x=[g   g  1  0  1  0  0  0  0  0  0];  %Meters 
%Clip_Locations_y=[0   3  6  9  12 15 18 21 24 27 30]; %Meters

%Zig zag high:
%Clip_Locations_x=[g   g  0  0  0  0  1  0  1  0  0];  %Meters 
%Clip_Locations_y=[0   3  6  9  12 15 18 21 24 27 30]; %Meters

%Traversing Route.
%Clip_Locations_x=[g   g   7   14  21  28];  
%Clip_Locations_y=[0   2   2   2   2   2];

%Sharp bends.
%Clip_Locations_x=[g   g 1  -1 0  0   0  8  8];  
%Clip_Locations_y=[0   2 4  6  10 12  18 18 24];

%Rounded bends.
%Clip_Locations_x=[g   g 1  -1 0  0   1   2    6.5 7.5 8];  
%Clip_Locations_y=[0   2 4  6  10 12  16  17.5 19  20  24];


%***************************************************************************************************
%*****Friction equation:

%Select the equation that calculates friction at the bends. Actual equations can be seen in the
%friction function at the bottom of the script. 

%Choices: 'Experimentally Found', 'Experimentally Found Mod', 'Capstan', 'Common', 'Common
%Modified', or 'Linear'.

%Experimentally Found - based on a rough garage experiment. Doesn't depend on friction coefficient
                        %variable. 
%Experimentally Found Mod - Probably the most accurate. The modification accounts for the higher
                            %than expected friction at low loads. Doesn't depend on friction
                            %coefficient variable.
%Capstan - Capstan equation. 
%Common - Common equation for friction FF=uN.
%Common Mod - Accounts for higher than expected friction at low loads. 
%Linear - linear relation between multiplier of 1 at 0 degrees and multiplier of 2.2 at 180 degrees. 
        %Doesn't depend on the friction coefficient variable because I got lazy. 

Friction_Equation='Experimentally Found Mod';
 

%***************************************************************************************************
%*****Friction Coefficient:

%I'm sure the friction coefficient depends on a lot of things. The coefficients below most closely
%matched the equations to the experimental data. 

%Common - 0.38
%Capstan - 1

Friction_Coefficient= .38;


%***************************************************************************************************
%*****Rope Linear Density:

%Linear density of rope based on black diamond 9.9mm standard rope. 
% Density=.064; %kgs/meter
Density=.0429; %lbs/ft. Imperial units for script. 


%***************************************************************************************************
%*****Path Resolution

%This is the spacing between x points on the path for the route. The bigger the spacing, the quicker
%the runtime. 0.1 seemed to be reasonable. 

path_spacing=.1; %meters


%***************************************************************************************************
%*****Caternary Iteration Position

%Enter the bend number you want to view the catenary iteration rope paths for. Will display between
%this clip and the next. If you don't want to see this, then I guess you can comment out the plot
%for it below.

cat_iter_clip=1;


%***************************************************************************************************
%*****Caternary Iteration Criteria
%Enter the percent change of drag calculated between iterations considered accurate enough to stop
%iterating. Specifically, percent change of RDa, or rope drag immediately after the bend. 

%If percent change is larger than 0.001, I found that it starts to be becomre inaccurate, and not
%that much computation time is gained by making it larger usually. And smaller than 0.001 starts to
%increase the computation time a lot for not much accuracy gain.
 
percent_change=.001;


%% Initializing Variables

%Not initializing. Just converting to imperial units to match calculations. 
meter2ft=3.28;
Clip_Locations_x=Clip_Locations_x*meter2ft;
Clip_Locations_y=Clip_Locations_y*meter2ft;
path_spacing=path_spacing*meter2ft;

%Saving the number of elements in the input array.
num_elements=length(Clip_Locations_x);

%Starting the path of the rope for route in x's and y's. First point is (0,0) Second is (0, how ever
%high the first clip is).
x_path=[0,0];
y_path=[0,Clip_Locations_y(2)];

%Total rope weight at each point.
Total_Rope_Weight=zeros(1,num_elements);

%Total friction drag at each point.
Total_Friction_Drag=zeros(1,num_elements);

%Want to plot the rope weight (RW) and friction drag (FD) on the same plot later, so below
%creates a matrix for rope weight drag in row 1 and friction drag in row 2.
RW_FD = zeros(2,num_elements); 

%Rope drag a nanometer above the clip. Not finding for the last clip, so 1 less element.
RDa = zeros(1,num_elements-1);

%Rope Drag a nanometer below the clip, for each clip.
RDb = zeros(1,num_elements); 

%Force of friction added by each clip. Not finding for the last clip, so 1 less element.
FF = zeros(1,num_elements-1); 

%Deflection angle of the rope at the points compared to a straight line path. Not finding for the
%last clip, so 1 less element.
Deflec_Angles=zeros(1,num_elements-1);

%Percent of total rope drag due to friction for every bend location.
Percent_Drag_Due_to_Friction = zeros(1,num_elements);

%Weight of the rope between current clip and the previous one.
Weight_Segment=zeros(1,num_elements);

%Heading of the rope going into the clip. Up is 90 deg, right is 0,
%etc.
Head_In=zeros(1,num_elements);

%Heading of the rope going out the clip. Up is 90 deg, right is 0, etc. Not finding heading out for
%the last clip, so 1 less element than the rest.
Head_Out=zeros(1,num_elements-1);

%Not initializing. Just changing the name to something more readable.
Heights = Clip_Locations_y;


%% Linear Approximation
% Finds forces based on linear path between points.


%***************************************************************************************************
%*****Calculating Linear Deflection Angles

for Position = 2:(num_elements-1) %For every clip except the first, find the deflection angle.
    
    %At the ground the angle will be zero. It is already initialized/stored as zero, so start the
    %loop at the second position. (first clip)
        
    %Coordinate system: Straight up is 90 deg. Directly right is 0 deg. Left 180. Down 270.
  
    if Position == 2  %If at the first clip, the heading into the bend is 90 deg.
        Head_In(Position)=90;
    end  %End heading in for first clip.

    %Store current and next x coordinates for easier reading.
    x_current=Clip_Locations_x(Position);
    x_next=Clip_Locations_x(Position+1);

    %Store current and next y coordinates for easier reading.
    y_current=Clip_Locations_y(Position);
    y_next=Clip_Locations_y(Position+1);
    
    %Find slope.
    Slope=((y_next-y_current)/(x_next-x_current));

    %Finding the heading of the rope going out of the bend. %Using Find_Heading function defined at
    %end of script.
    Head_Out(Position)=Find_Heading(x_current,x_next,Slope);
   
    %Find deflection angle. There are a couple conditions where you have to adjust things to do the
    %math.
    if (abs(Head_Out(Position)-Head_In(Position))) > 180
        dif=(abs(Head_Out(Position)-Head_In(Position)));
        Deflec_Angles(Position)=(abs(Head_Out(Position)-Head_In(Position))) - (2*(dif-180));

    else
        Deflec_Angles(Position)=abs(Head_Out(Position)-Head_In(Position)); 
    end
    
    
    %The heading in for the next clip will be the current heading out.
    Head_In(Position+1)=Head_Out(Position);
    
    
    %Loop back for next coordinate pair, or "clip".
    
end  %End calculating deflection angles for every coordinate pair, or "clip".


%***************************************************************************************************
%*****Calculate linear approximation of forces for every clip position.

for Clip = 2:num_elements %For all clip positions, excluding ground (clip 0), find forces and values. 
   %All values are zero at the ground, which is right, so ground is excluded. 
    
   %Need to access the values stored for the previous clip, so this is an index for the previous
   %clip.
   Clip_Below=Clip-1;
    
   
   %*****Weight of Rope Segment
   %Weight of segment of rope between current clip and the previous clip = (difference in heights) *
   %(linear rope density.)
   Weight_Segment(Clip)=((Heights(Clip)-Heights(Clip_Below)))*Density; 
   
   
   %*****Rope Drag Before Clipping
   %(Drag force a nanometer below the current clip) = (Drag force a nanometer above last clip) +
   %(Weight of segment below). RDa was set as an all zero row vector in the initialization section.
   RDb(Clip)=RDa(Clip_Below)+Weight_Segment(Clip);
   
   if Clip < num_elements  %Find 'rope drag after' and 'force of friction' if not at the last clip. 
       %Don't want to try to find those values after the end of the route. 
       
       %*****Rope Drag After Clipping
       %Calls the friction fuction defined at the bottom of the script.
       RDa(Clip)=RDb2RDa(Friction_Equation,RDb(Clip),Deflec_Angles(Clip),Friction_Coefficient);
      
       %*****Force of Friction
       %Force of friction is drag after - drag before.
       FF(Clip)=(RDa(Clip)-RDb(Clip));
   end  %End finding rope drag after clip and force of friction. 
   
 
   %*****Weight of the Rope
   %Total weight of the rope at current height.
   Total_Rope_Weight(Clip)=Heights(Clip)*Density;  %Total weight of the rope at current height.
   %Putting rope weight at current height in matrix that is plotted later. 
   RW_FD(1,Clip)=Total_Rope_Weight(Clip); 
   
   %*****Total Friction Drag Before Clipping
   %This finds the total friction drag a nanometer before the clip.
   %Friction_Drag = Rope drag before - Total rope weight
   Total_Friction_Drag(Clip)=(RDb(Clip)- Total_Rope_Weight(Clip));
   %Adding Friction Drag to matrix that we plot later.
   RW_FD(2,Clip)= Total_Friction_Drag(Clip);
   
   %*****Pecent of the rope drag that is due to friction.
   %Friction rope drag / Total rope drag   *100
   Percent_Drag_Due_to_Friction(Clip)=((Total_Friction_Drag(Clip))/RDb(Clip))*100;
   
end  %End calculating all forces and values at every clip.

%Storing linear approximation values. 
FF_Linear=FF;
Weight_Segment_Linear=Weight_Segment;
Percent_Drag_Due_to_Friction_Linear=Percent_Drag_Due_to_Friction;
RDb_Linear=RDb;
RDa_Linear=RDa;
Total_Friction_Drag_Linear=Total_Friction_Drag;

%Creating a matrix with interesting values that won't be displayed unless you want to.  
Rope_Weight_Friction_Total_Linear=zeros(4,num_elements);
Rope_Weight_Friction_Total_Linear(1,:)=0:(length(Total_Rope_Weight)-1);
Rope_Weight_Friction_Total_Linear(2,:)=Total_Rope_Weight;
Rope_Weight_Friction_Total_Linear(3,:)=Total_Friction_Drag;
Rope_Weight_Friction_Total_Linear(4,:)=RDb;
Max_RDb_Linear=max(RDb);


%% Catenary Approximation
% Finds forces based on a catenary path between points using the linear approximation as initial
% guess. 

%For more info on Catenary curves:
    %https://en.wikipedia.org/wiki/Catenary


%Starting figure for plot of catenary iterations on a specific clip.
figure
%Initializing counter for plot. 
iter_count = 0;

for Clip = 2:(num_elements-1) %For all clip positions, excluding ground and last clip.
    %Values are all zero at the ground, so we exclude ground. 

    %x/y values stored in smaller variables. 
    xc = Clip_Locations_x(Clip);    %x value of current point.
    yc = Clip_Locations_y(Clip);    %y value of current point.
    xn = Clip_Locations_x(Clip+1);  %x value of next point.
    yn = Clip_Locations_y(Clip+1);  %y value of next point.

    %Difference in x and y from next to current.
    dx=(xn-xc);
    dy=(yn-yc);
    
    if dx==0 && Clip_Locations_x(Clip-1)==xc %If the next clip is directly up, and the previous clip is directly below. 
                 
        %*****Rope Drag After Clipping
        RDa(Clip)=RDb(Clip);
        
        %*****Force of Friction
        %Force of friction is drag after - drag before
        FF(Clip)=(RDa(Clip)-RDb(Clip));

        %*****RDb Next Clip
        %(Drag force a nanometer below the current clip) = (Drag force a nanometer above last clip) +
        %(Weight of segment below). 
        RDb(Clip+1)=RDa(Clip)+Weight_Segment(Clip+1);
        
        %*****Total Rope Weight Next Clip
        %Total rope weight is the sum of all the segments up to the current clip. 
        Total_Rope_Weight(Clip+1)=Total_Rope_Weight(Clip)+Weight_Segment(Clip+1);
        %Putting rope weight at current height in matrix that we plot later. 
        RW_FD(1,Clip+1)=Total_Rope_Weight(Clip+1);

        %*****Total Friction Drag Next Clip
        %Friction_Drag = Rope drag before - Total rope weight
        Total_Friction_Drag(Clip+1)=(RDb(Clip+1)-Total_Rope_Weight(Clip+1));
        %Adding Friction Drag to matrix that we plot later.
        RW_FD(2,Clip+1)= Total_Friction_Drag(Clip+1);

        %*****Pecent of the rope drag that is due to friction next clip.
        %Friction rope drag / Total rope drag   *100
        Percent_Drag_Due_to_Friction(Clip+1)=((Total_Friction_Drag(Clip+1))/RDb(Clip+1))*100;
        
        
    elseif dx==0  %If the next clip is directly up, and the previous clip is not directly below.
        %The deflection angle at the current clip changed because the previous segment follows a
        %catenary curve.  
        
        %Find new deflection angle.
        if (abs(Head_Out(Clip)-Head_In(Clip))) > 180
            dif=(abs(Head_Out(Clip)-Head_In(Clip)));
            Deflec_Angles(Clip)=(abs(Head_Out(Clip)-Head_In(Clip))) - (2*(dif-180));

        else
            Deflec_Angles(Clip)=abs(Head_Out(Clip)-Head_In(Clip)); 
        end

        
        %*****Rope Drag After Clipping
        %According to capstan equation. https://en.wikipedia.org/wiki/Capstan_equation
        RDa(Clip)=RDb2RDa(Friction_Equation,RDb(Clip),Deflec_Angles(Clip),Friction_Coefficient);
        %RDa(Clip)=((RDb(Clip))/(exp(-1*Friction_Coefficient*(deg2rad(Deflec_Angles(Clip))))));
        %RDa(Clip)=(((-.00001*RDb(Clip))-.000002)*((Deflec_Angles(Clip))^2)) +  (((0.0077*RDb(Clip))+.0036)*Deflec_Angles(Clip)) + RDb(Clip);

        %*****Force of Friction
        %Force of friction is drag after - drag before
        FF(Clip)=(RDa(Clip)-RDb(Clip));

        %*****RDb Next Clip
        %(Drag force a nanometer below the current clip) = (Drag force a nanometer above last clip) +
        %(Weight of segment below). PFa was set as an all zero row vector in the initialization section.
        RDb(Clip+1)=RDa(Clip)+Weight_Segment(Clip+1);
        
        %*****Total Rope Weight Next Clip
        %Total rope weight is the sum of all the segments up to the current clip. 
        Total_Rope_Weight(Clip+1)=sum(Weight_Segment(1:Clip+1));
        %Putting rope weight at current height in matrix that we plot later. 
        RW_FD(1,Clip+1)=Total_Rope_Weight(Clip+1);

        %*****Total Friction Drag Next Clip
        %Friction_Drag = Rope drag before - Total rope weight
        Total_Friction_Drag(Clip+1)=(RDb(Clip+1)-Total_Rope_Weight(Clip+1));
        %Adding Friction Drag to matrix that we plot later.
        RW_FD(2,Clip+1)= Total_Friction_Drag(Clip+1);

        %*****Pecent of the rope drag that is due to friction next clip.
        %Friction rope drag / Total rope drag   *100
        Percent_Drag_Due_to_Friction(Clip+1)=((Total_Friction_Drag(Clip+1))/RDb(Clip+1))*100;

        
    else %If the next clip is not directly up, the path will be a catenary. Loop to find catenary approximation.

        %Initializing some variables.
        Previous_RDa=RDa(Clip);
        New_RDa=0;
        
        %Find better approximations of RDa until the percent change in the approximation is below
        %the percent change input value.
        while ((abs((Previous_RDa-New_RDa)/(Previous_RDa)))*100) > percent_change

            %Below are the parameters that define the shape of the catenary curve. (Horizontal component
            %of tension, and linear density of rope.
            RDa_h=(abs(cosd(Head_Out(Clip)))*RDa(Clip));  %Horizontal component of RDa at the current clip.
            d=Density;

            %Combining these parameters into a single term. 
            a=RDa_h/d;

            %The shape of the curve is defined. The problem is that the correct position in space to
            %show the path between clips is not known. The curve, without translation, is centered
            %on x=0.

            
            %*****Translating Catenary Curve

            %To find where the curve should be moved to, points on the curve that are the same distance
            %apart in x and y as our actual clips are found. This yields coordinates on the curve that
            %represent our clips. These coordinates are then matched in space to our actual clip
            %locations by translating the curve.

            %Creating a symbolic variable to solve for below. 
            syms x;

            %y's are equal for both points if the curve for the second point is translated dx and dy.
            %eq1=eq2.
            eq1=(a*cosh(x/a));
            eq2=(a*cosh((x+dx)/a))-dy;

            %Solving the equation for the point on the curve that represents where the current clip
            %x value is on the non-translated catenary curve. 
            x1_Catenary=vpasolve(eq1==eq2,x);

            %The representative y value for the current clip is found. 
            y1_Catenary=(a*cosh(x1_Catenary/a));

            %The differences between the representative current clip coordinates on the curve and the
            %actual current clip coordinate are found. These offsets are used to translate the curve
            %when storing the path points below. 
            x_off=(xc-x1_Catenary);
            y_off=(yc-y1_Catenary);

            %Just for informational purposes, the equation for the catenary approximation of the
            %path of the rope from the current clip to the next clip is:
            %y=a*cosh((x-x_off)/a))+y_off)


            %*****Finding New Deflection Angle

            %With this new path between points, the heading of the rope out of the current clip is
            %different than before. This also means that deflection angle, force of friction, and
            %therefor DFa is different than before. Below we find the new RDa estimation according
            %to this new heading out of the clip. We then loop back with the new RDa to find a new
            %catenary approximation. With more iterations the approximation will approach the actual.

            %The derivative of the path equation is:
            %sinh((x-x_off)/a))

            %Finding slope at xc:
            Slope_xc=sinh((xc-x_off)/(a));

            %Finding the heading of the rope out of the bend. Using Find_Heading function defined at
            %end of script.
            Head_Out(Clip)=Find_Heading(xc,xn,Slope_xc);

            %Find deflection angle. There are a couple conditions where you have to adjust things to
            %do the math.
            if (abs(Head_Out(Clip)-Head_In(Clip))) > 180
                dif=(abs(Head_Out(Clip)-Head_In(Clip)));
                Deflec_Angles(Clip)=(abs(Head_Out(Clip)-Head_In(Clip))) - (2*(dif-180));
                
            else
                Deflec_Angles(Clip)=abs(Head_Out(Clip)-Head_In(Clip)); 
            end

            
            %*****Finding New RDa Approximation

            %Storing the RDa before it is calculated with new information. 
            Previous_RDa=RDa(Clip);

            %Using the friction equation function to find the new RDa.
            RDa(Clip)=RDb2RDa(Friction_Equation,RDb(Clip),Deflec_Angles(Clip),Friction_Coefficient);

            %Storing the new RDa so it can compare vs the old.
            New_RDa=RDa(Clip);
            
            %*****Plot of iterating paths at certain clip.
            if Clip==cat_iter_clip+1
                iter_count = iter_count+1;
                x_path_seg_test=min([xc xn]):path_spacing:max([xc xn]);
                if xc>xn %If route goes left.
                    %If route is going left from 0 to -1, the above line would make a vector from -1 to 0.
                    %You have to give a positive interval, so you can't put in xc:path_spacing:xn if going
                    %left. Need to flip to go from 0 to -1.
                    x_path_seg_test=flip(x_path_seg_test);
                end


                y_path_seg_test=zeros(1,length(x_path_seg_test));
                for i=1:length(x_path_seg_test)
                    y_path_seg_test(i)=((a*cosh((x_path_seg_test(i)-x_off)/a))+y_off);
                end
                
                %Converting to meters. 
                x_path_seg_test=x_path_seg_test/meter2ft;
                y_path_seg_test=y_path_seg_test/meter2ft;
                
                plot(x_path_seg_test,y_path_seg_test)
                hold on
            end %End looking at a specific clips catenary iterations. 

            %Loop back with new RDa estimation based on the newest catenary path iteration.
            
        end  %End iterating to find catenary rope path and RDa for the current 'clip'.
    

        %***************************************************************************************************
        %*****Finding/Storing Other Forces and Values

        %*****Force of Friction Current Clip
        %FF is the difference between force before and after clip.
        FF(Clip)=(RDa(Clip)-RDb(Clip));

        %*****Heading In Next Clip
        %Finding slope going into next clip:
        Slope_xn=sinh((xn-x_off)/(a));

        %Finding heading in to the next bend using the Find_Heading function defined at end of script. 
        Head_In(Clip+1)=Find_Heading(xc,xn,Slope_xn);

        %*****RDb Next Clip
        %The defining factor of a catenary curve is that the horizontal components of tension are the
        %same everywhere on the curve. With this, we know that the horizontal component of RDa found
        %previously is the same as for RDb. This can be used to directly find the RDb for the next clip.
        RDb(Clip+1)=((RDa_h)/(abs(cosd(Head_In(Clip+1)))));


        %*****Weight of Next Segment to Next Clip
        %Weight of the next segment of rope is the difference between the drag force after the current
        %clip and the drag force before the next clip.
        Weight_Segment(Clip+1)=(RDb(Clip+1)-RDa(Clip));


        %*****Total Rope Weight Next Clip
        %Total rope weight is the sum of all the segments up to the current clip. 
        Total_Rope_Weight(Clip+1)=sum(Weight_Segment(1:Clip+1));
        %Putting rope weight at current height in matrix that we plot later. 
        RW_FD(1,Clip+1)=Total_Rope_Weight(Clip+1);


        %*****Total Friction Drag Next Clip
        %Friction_Drag = Rope drag before - Total rope weight
        Total_Friction_Drag(Clip+1)=(RDb(Clip+1)-Total_Rope_Weight(Clip+1));
        %Adding Friction Drag to matrix that we plot later.
        RW_FD(2,Clip+1)= Total_Friction_Drag(Clip+1);


        %*****Pecent of the rope drag that is due to friction next clip.
        %Friction rope drag / Total rope drag   *100
        Percent_Drag_Due_to_Friction(Clip+1)=((Total_Friction_Drag(Clip+1))/RDb(Clip+1))*100;
    
    
    end  %End if/else for whether or not the next clip is directly up.
    
    
    
    %*****Rope Path Segment
    %Storing the rope path for the segment. 
    
    if xc == xn  %If the path is directly up.
        x_path_seg = [xc xn];
        y_path_seg = [yc yn];
    else
        x_path_seg=min([xc xn]):path_spacing:max([xc xn]);
        if xc>xn %If route goes left.
            %If route is going left from 0 to -1, the above line would make a vector from -1 to 0.
            %You have to give a positive interval, so you can't put in xc:path_spacing:xn if going
            %left. Need to flip to go from 0 to -1.
            x_path_seg=flip(x_path_seg);
        end
        
        y_path_seg=zeros(1,length(x_path_seg));
        for i=1:length(x_path_seg)
            y_path_seg(i)=((a*cosh((x_path_seg(i)-x_off)/a))+y_off);
        end
        %Making sure the path ends exactly at the next point.
        x_path_seg(length(x_path_seg))=xn;
        y_path_seg(length(y_path_seg))=yn;
    end  %End finding path of the segment whether or not the next point is directly up. 

    
    %*****Rope Path Total
    %Appending the segment path on to the end of the total path so far. Could improve this by not
    %changing the array size every loop...
    x_path=[x_path,x_path_seg];
    y_path=[y_path,y_path_seg];

    
    %Loop back for next clip.
    
end %End looping for every clip. 

%Converting all of the route distance info from feet back to meters.
Clip_Locations_x=Clip_Locations_x/meter2ft;
Clip_Locations_y=Clip_Locations_y/meter2ft;
x_path=x_path/meter2ft;
y_path=y_path/meter2ft;


%% Total Route Rope Length

%***** Initializing variables
Route_Length = 0;
Delta_x = 0;
Delta_y = 0;
Dist_between_points = 0;


%***** Caclculating distances between points on the catenary path of the route and returning the
%total rope length of the route.
for i=1:(length(x_path)-1)
    Delta_x=((x_path(i+1))-(x_path(i)));
    Delta_y=((y_path(i+1))-(y_path(i)));
    Dist_between_points = (((Delta_x)^2)+((Delta_y)^2))^.5;
    Route_Length=Route_Length+Dist_between_points;
end
    

%% Displaying Results

disp('********************************************************************************************')
disp(' ')
disp(['Friction equation used: ', Friction_Equation])
disp(' ')
disp('Vertical height of the route (meters):')
disp(Clip_Locations_y(num_elements))

disp('Rope length of the route (meters):')
disp(Route_Length)


FF_Matrix=[FF_Linear;FF];
disp('Force of friction added at clips (lbs):')

disp('Linear        Catenary')
disp(FF_Matrix.')


Percent_Drag_Due_to_Friction;
disp('Percent of rope drag due to friction right before clipping - catenary approximation:')
disp(Percent_Drag_Due_to_Friction.')

%Creating a matrix with interesting values. 
Rope_Weight_Friction_Total=zeros(4,num_elements);
Rope_Weight_Friction_Total(1,:)=0:(length(Total_Rope_Weight)-1);
Rope_Weight_Friction_Total(2,:)=Total_Rope_Weight;
Rope_Weight_Friction_Total(3,:)=Total_Friction_Drag;
Rope_Weight_Friction_Total(4,:)=RDb;

%Displaying rope weight, friction, and total friction matrix below. 
disp(' ')
disp('**** Rope drag right before clipping - catenary approximation (lbs)****')
disp(' ')
disp('Clip Num   Rope Weight    Friction    Total')
disp(Rope_Weight_Friction_Total.')


%Display max rope drag. 
disp('Max Rope Drag *** Linear Approximation *** (lbs):')
disp(Max_RDb_Linear)
disp('Max Rope Drag *** Catenary Approximation *** (lbs):')
disp(max(RDb))


RW_FD;
%Removing the first zeros make the position match the clip number for plotting. 
%Rows 1 through 2 and colums 2 through however many there are.
Sliced_RW_EW=RW_FD(1:2,2:num_elements);

%Same thing for all of the angles.
Sliced_Angles=Deflec_Angles(2:(num_elements-1));


%% Plot of Catenary Iterations

%The plot was created in one of the catenary loops above.
%Plot adjustments.
hold off
iter_clip_start=cat_iter_clip;
iter_clip_end=cat_iter_clip+1;
title(['Catenary Iterations from Clip ',num2str(iter_clip_start),' to Clip ',num2str(iter_clip_end)])
xlabel('Meters')
ylabel('Meters')
%Legend for plot. 
if iter_count==1
    legend('1st')
elseif iter_count==2
    legend('1st','2nd')
elseif iter_count==3
    legend('1st','2nd','3rd')
else
    legend('1st','2nd','3rd','4th')
end


%% Plot of Route - Catenary Approximation


figure
plot(x_path,y_path);
title('Rope Path')
xlabel('Meters')
ylabel('Meters')

%Set left and right limits for plot axis so that the aspect ratio will be
%correct for a square plot. If the aspect ratio is off it might look like the
%angles of the rope are huge when they are not, and vice versa. 
Max_Height=Clip_Locations_y(num_elements);
Max_Width=max(Clip_Locations_x)-min(Clip_Locations_x);

if Max_Height>Max_Width %If the route goes up more than it spans horizontally.
    Left_Limit=-1*(Max_Height/1.75);
    Right_Limit=(Max_Height/1.75);
    %axis adjustment on plot and formatting.
    axis([Left_Limit, Right_Limit, 0, max(Clip_Locations_y)+1.5]);
else %If the route spans horizontally more than it goes up.
    Left_Limit=-1*(Max_Height/1.75);
    Right_Limit=(Max_Height/1.75);
    %axis adjustment on plot and formatting.
    axis([(min(Clip_Locations_x)-1), (max(Clip_Locations_x)+1), 0, (Max_Width+2)]);
end

%Overlay clip locations
hold on
scatter(Clip_Locations_x,Clip_Locations_y, 'k')

%Loop below is just adding clip number labels.
Clip_Num=[0:(num_elements-1)];
for t = 1:numel(Clip_Locations_x)
  text(Clip_Locations_x(t)+0.05,Clip_Locations_y(t)+0.05,[' ',num2str(Clip_Num(t)),' '])
end
hold off


%% Plot of Total Drag

%Plot of the total friction with horizontal bar plot, stacking the rope
%weight and friction components.
figure
barh(Sliced_RW_EW.','stacked')
legend('Rope Weight','Friction')
title('Rope Drag')
xlabel('lbs')
ylabel('Bend Number')


%% Plot of Rope Deflection Angles

%Plot of the angle of the rope deflected off a straight line path at each bend. 
figure
barh(Sliced_Angles.','stacked')
title('Bend Angle')
xlabel('Degrees')
ylabel('Bend Number')
axis([0, 180, 0, num_elements]);


%% Code Info
% Outline

%	• Inputs
% 	• General Setup
% 	• Variable Initialization
% 	• Linear Approximation
% 	• Catenary Approximation
% 	• Length of Route
% 	• Display Results
% 	• Plot Results


%% Functions
% Find_Heading function, Drag_After function. 

function Heading=Find_Heading(x1_coordinate, x2_coordinate, slope)

    %Finding the angle in degrees from the slope.
    ang=atand(slope);

    %Finding a better approximation of the heading of the rope going out of the clip. Directly
    %up is 90 degrees, left is 180, down is 270, etc.
    if (slope >= 0) && (x1_coordinate < x2_coordinate)  %If slope is positive or zero, and going route is right:
        Heading=ang;

    elseif (slope >= 0) && (x1_coordinate > x2_coordinate)  %If slope is positive or zero, and route is going left:
        Heading=ang+180;

    elseif (slope < 0) && (x1_coordinate < x2_coordinate)  %If negative slope and route is going right:
        Heading=ang+360;
        
    elseif (slope < 0) && (x1_coordinate > x2_coordinate)  %If negative slope and route is going left:
        Heading=ang+180;

    elseif x1_coordinate == x2_coordinate %If route is going straight up:
        Heading = 90;

    end  %End finding new heading out.

end  %End Find_Heading function.


function Drag_After=RDb2RDa(Friction_Equation,Rope_Drag_Before,Deflection_Angle,Friction_Coefficient)
    
    if strcmp(Friction_Equation,'Experimentally Found Mod')
        Drag_After=(((-10^-5)*((Deflection_Angle)^2))+(.0095*(Deflection_Angle))+1)*Rope_Drag_Before;
        
        %At low loads, the formula underestimates drag a little. Below multiplies by a mod factor to
        %adjust if at low loads. Just linearized factor from 1.2 to 1, for 0-2 lbs. 
        if Rope_Drag_Before < 1
            Low_Drag_Range=[0 1];
            Mod_Range=[1.6 1];
            Low_Drag_Mod_Factor=interp1(Low_Drag_Range,Mod_Range,Rope_Drag_Before);
            Drag_After=Drag_After*Low_Drag_Mod_Factor;
        end
        
    elseif strcmp(Friction_Equation,'Experimentally Found')
        Drag_After=(((-10^-5)*((Deflection_Angle)^2))+(.0095*(Deflection_Angle))+1)*Rope_Drag_Before;
        
    elseif strcmp(Friction_Equation,'Capstan')
        Drag_After=((Rope_Drag_Before)/(exp(-1*Friction_Coefficient*(deg2rad(Deflection_Angle)))));
        
    elseif strcmp(Friction_Equation,'Common')
       %The common equation for friction is:
       %(Force of friction) = (Friction coefficient) * (Normal force)
       %Also, (Force of friction) = (Rope drag after) - (Rope drag before)
       %Combining: (Rope drag after) - (Rope drag before) = (Friction coefficient) * (Normal force)

       %The (Normal Force) can be found in terms of (Rope drag before), (Rope drag after), and the
       %angles, with static equalibrium equations. With that, the only unknown in the combined equation
       %above is (Rope drag after) and we can solve.

       %Creating a sybolic variable to solve for the (Rope drag after).
       syms x
       %Since we don't care about the direction of the normal force for the equation, only the
       %magnitude, to make the calculation cleaner the (Rope drag after) vector is oriented to be
       %completely in the i direction. The relative angle between the two vectors is still the same
       %doing that. 
       %i components of the two vectors at the clip. 
       i=((Rope_Drag_Before*cosd(180-Deflection_Angle))+x);
       %j components of the two vectors at the clip. 
       j=((Rope_Drag_Before*sind(180-Deflection_Angle)));
       %Normal force:
       N=((i^2)+(j^2))^.5;
       %Solving the equation and storing (Rope drag after) in "RDa"
       Drag_After=double(solve(x==((N*Friction_Coefficient)+Rope_Drag_Before)));
       
       
    elseif strcmp(Friction_Equation,'Common Modified') 

       syms x
       i=((Rope_Drag_Before*cosd(180-Deflection_Angle))+x);
       j=((Rope_Drag_Before*sind(180-Deflection_Angle)));
       N=((i^2)+(j^2))^.5;
       Drag_After=double(solve(x==((N*Friction_Coefficient)+Rope_Drag_Before)));
       
       %At low loads, the formula underestimates drag a little. Below multiplies by a mod factor to
       %adjust if at low loads. Just linearized factor from 1.2 to 1, for 0-2 lbs. 
       if Rope_Drag_Before < 1
           Low_Drag_Range=[0 1];
            Mod_Range=[1.6 1];
            Low_Drag_Mod_Factor=interp1(Low_Drag_Range,Mod_Range,Rope_Drag_Before);
            Drag_After=Drag_After*Low_Drag_Mod_Factor;
       end
        
    elseif strcmp(Friction_Equation,'Linear')
        %Based on the fact that pulling a 20 lb weight 180 deg over an i-beam construction carabiner
        %required about 44 lbs to move. 20 * 2.2 = 44
        Angle_Range=[0 180];
        Mod_Range=[1 2.2];
        Linear_Conversion_Factor=interp1(Angle_Range, Mod_Range, Deflection_Angle);
        Drag_After=Rope_Drag_Before*Linear_Conversion_Factor;
    else
        disp('You did not enter a valid input for Friction_Equation in the input section.')
        disp('Enter "Experimentally Found", "Capstan", "Common", or "Linear"')
    end
    
end %yay. 935 lines? wow.
