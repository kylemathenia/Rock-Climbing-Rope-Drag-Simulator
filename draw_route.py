# https://stackoverflow.com/questions/37363755/python-mouse-click-coordinates-as-simply-as-possible?rq=1


import numpy as np
import matplotlib.pyplot as plt


class LineBuilder:
    def __init__(self, line,ax,color):
        #imshow object called "line"
        self.line = line
        #the plot called "ax"
        self.ax = ax
        self.color = color
        #x coordinate click data
        self.xs = []
        #y coordinate click data
        self.ys = []
        #'button_press_event' is the event. When the event happens the function 'self' is called with a 'MouseEvent' class instance variable as the event. The function 'self' is the __call__ fuction below. mpl_connect opens a connection and somehow doesn't let the program finish until it is disconnected?
        self.cid = line.figure.canvas.mpl_connect('button_press_event', self)
        self.counter = 0
        self.shape_counter = 0
        self.shape = {}
        self.precision = 1

    #__call__ allows the instance of the LineBuilder class to behave like a function. 
    def __call__(self, event):
        #if right click, exit the figure. 
        if str(event.button) == 'MouseButton.RIGHT': plt.close()
        else:
            if event.xdata==None:
                x_coor=event.xdata
                y_coor=event.ydata
            #else rounded to 1 decimal place.
            else:
                x_coor=round(event.xdata,1)
                y_coor=round(event.ydata,1)
            #if the click was not on the axes (plot), return. 
            if event.inaxes!=self.line.axes: return
            #if this is the first click
            if self.counter == 0:
                self.xs.append(x_coor)
                self.ys.append(y_coor)
                self.ax.scatter(self.xs,self.ys,s=10,color='red')
                self.ax.plot(self.xs,self.ys,color=self.color)
                self.line.figure.canvas.draw()
                self.counter = self.counter + 1
                
            else:
                if self.counter != 0:
                    #append the first click x coordinate to the end the list.
                    self.xs.append(x_coor)
                    #append the first click y coordinate to the end the list.
                    self.ys.append(y_coor)
                #add a point on the plot. #s is the size in pixels.
                self.ax.scatter(self.xs,self.ys,s=10,color='red')
                #add a point on the plot. #s is the size in pixels.
                self.ax.plot(self.xs,self.ys,color=self.color)
                self.ax.set_title('(Right click to exit.)\ndx: '+str(round((x_coor-self.xs[self.counter-1]),1))+' m, dy: '+str(round((y_coor-self.ys[self.counter-1]),1))+' m')
                
                #redraw the current figure line. 
                self.line.figure.canvas.draw()
                self.counter = self.counter + 1
                self.shape[0] = [self.xs,self.ys]

def create_shape_on_image(data,cmap='jet'):
    
    #Just reshapse the array.
    def change_shapes(shapes):
        new_shapes = {}
        for i in range(len(shapes)):
            l = len(shapes[i][1])
            new_shapes[i] = np.zeros((l,2))
            for j in range(l):
                new_shapes[i][j,0] = shapes[i][0][j]
                new_shapes[i][j,1] = shapes[i][1][j]
        return new_shapes
    
    #Creates an empty figure.
    fig = plt.figure()
    
    #This makes the figure full screen. Control f to exit.
    fig.canvas.manager.full_screen_toggle()
    
    #plt.get_current_fig_manager().window.showMaximized() #Doesn't work with older version of matplotlib
    #adds a subplot to that figure. 111 represents position of the plot on the figure. 1 row, 1 column, 1 index. A plot is called an 'axes'. ax is short for plot.
    ax = fig.add_subplot(111)
    #sets a title for the plot. 
    ax.set_title('Click to set rope path.')
    #setting the limits of the plot according to data. (left limit, right limit) data.shape[1] is the N dimension of the image. (100)
    ax.set_xlim(-1*data.shape[1]/2,data.shape[1]/2)
    #setting the limits of the plot according to data. (lower limit, upper limit) data.shape[0] is the M dimension of the image. (100)
    ax.set_ylim(0,data.shape[0])
    #creates an image object, or shows an image on the plot. Data is 'img' variable passed into function. extent is how the image lays on the plot. get_xlim() returns the x left and right limits in a tuple. The axes need to match the plots, which was set above. aspect just makes it fill up the whole space. 
    line = ax.imshow(data, extent=(ax.get_xlim()[0],ax.get_xlim()[1],ax.get_ylim()[0],ax.get_ylim()[1])) 
    
    #Creates a linebuilder instance with the imshow object called "line", the plot called "ax" and a color for the line. 
    linebuilder = LineBuilder(line,ax,'cyan')
    plt.gca()
    plt.show()
    new_shapes = change_shapes(linebuilder.shape)
    return new_shapes


def get_input(route_height):
    #100x100 array with a depth of 3 in each cell with values that represent RGB. (M, N, 3): an image with RGB values (0-1 float or 0-255 int). The first two dimensions (M, N) define the rows and columns of the image. 100x100 because the figure size is 100x100. Need to be able to pass in values for the size of the image to set the size of the plot. 
    img = np.zeros((route_height,route_height,3),dtype='uint')
    shapes = create_shape_on_image(img)[0]
    shapes=shapes.tolist()
    #insert a starting point at the beginning that is directly below the first x value. 
    
    return shapes