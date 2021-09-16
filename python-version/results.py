# This file plots the route. 


import matplotlib.pyplot as plt


    
#takes in a route object and returns a figure. 
def plot_results(route):
    fig = plt.figure(figsize=[10,4.8])

    route_plot = fig.add_subplot(131,title='Route',facecolor='white', aspect='equal', xlabel='Meters', ylabel='Meters', xmargin=.2)
    route_plot.spines['right'].set_visible(False)
    route_plot.spines['top'].set_visible(False)
    route_plot.plot(route.path_x_vals,route.path_y_vals,'c')
    route_plot.scatter(route.x_vals,route.y_vals,s=10,c='red')
    for i in range(0,len(route.x_vals)):
        route_plot.annotate(str(i), # this is the text
                  (route.x_vals[i],route.y_vals[i]), # this is the point to label
                  textcoords="offset points", # how to position the text
                  xytext=(10,-3), # distance from text to points (x,y)
                  ha='center',
                  color='black')
    plt.tight_layout()
    
    bend_angles = fig.add_subplot(132,title='--Ctr f to exit--\n\nBend Angles', xlabel='Degrees', ylabel='Bend')
    labels=[str(i) for i in range(1,len(route.deflec_angles))]
    width=.75
    bend_angles.barh(labels, route.deflec_angles[1:], width)
    plt.tight_layout()
    
    drag = fig.add_subplot(133,title='Rope Drag', xlabel='Lbs', ylabel='Bend')
    labels=[str(i) for i in range(1,len(route.total_rope_weight))]
    drag.barh(labels, route.total_rope_weight[1:], width, label='Rope Weight')
    drag.barh(labels, route.total_friction_drag[1:], width, left=route.total_rope_weight[1:], label='Friction')
    drag.legend()
    
    plt.tight_layout()
                    
    return fig
    


        
#takes in a route object and returns a fig for the catenary iterations. 
def plot_cat_iterations(route):
    fig = plt.figure(figsize=[8,6])

    title='Catenary Path Iterations between bend {} and {}'.format(route.cat_path_point,route.cat_path_point+1)
    route_plot = fig.add_subplot(111,title=title,facecolor='black', aspect='equal', xlabel='Meters', ylabel='Meters')
    route_plot.plot(route.cat_iters_pathx,route.cat_iters_pathy,'c')
    return fig
    
