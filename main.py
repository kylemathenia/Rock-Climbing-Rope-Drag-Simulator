# -*- coding: utf-8 -*-
"""Vist https://sites.google.com/view/relativelyrad/rope-drag-simulation/motivation-methods
for more info about how it works."""



import rds_funcs
import draw_route
import simulation
import results
import warnings


warnings.simplefilter("ignore",UserWarning)


def main():
    print('\n'*2)
    plot_height=30    #initial plot height.
    
    #Loop simulator forever.
    while True:
        #get info from user.
        mode=rds_funcs.ask_draw_or_enter()
        if mode=='draw':
            plot_height=rds_funcs.ask_area_height(plot_height)
            points=(draw_route.get_input(plot_height))
        else:  #mode=='enter'
            points=rds_funcs.ask_for_route()
        
        
        #create an instance of the Route class. 
        route=simulation.Route(points)
        
        
        while True:
            try:
                #Get approximation for route.
                route.catenary_approx()
                #route.linear_approx() #This could be used for a linear approximation.
                
                #Get results and show.
                fig=results.plot_results(route)
                fig.canvas.manager.full_screen_toggle()
                fig.show()
                rds_funcs.print_results(route)
                    
                #Save data. (y/n)
                save_data=rds_funcs.ask_save_data()
                if save_data==True:
                    rds_funcs.save_data(route)
                break
            except:
                print('\nThere was an error.\n\n')
                break

if __name__=='__main__':
    main()
