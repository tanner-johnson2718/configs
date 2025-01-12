# script contains functions for visuaulizing the nonlinear transport equation : u_t + u*u_x = 0 for u(0,x) = f(x)
# visualizations and solutions use method of characteristic lines i.e. lines where u remains constant.

# todo add shock dynamics

from matplotlib import pyplot as plt
from operator import add
import math
from scipy.optimize import fsolve
import numpy as np

def uniform(x, y, n):
    ys = []
    delta = (y - x) / n
    for i in range(0, n):
        ys.append(i * delta + x)
    return ys


# plot char lines of non linear transport equation given init functoin f
# also for each par, calculate where they intersect. Then find the t for
# which the first set of lines intersect for t > 0
def char_lines(f, num_lines, min_y, max_y, max_t):
    
	# compute char lines
	y_1s = uniform(min_y, max_y, num_lines)
	slopes = list(map(f,y_1s))
	y_2s = list(map(add , [i * max_t for i in slopes], y_1s))

    # for each par of lines calculate the (t,x) value of their intersection
	t_min = max_t + 1
	x_min = 0
	i_min = -1
	j_min = -1
	for i in range(0, num_lines):
		for j in range(i + 1, num_lines):
			if abs(slopes[i] - slopes[j]) < .00000001:
				continue

			t_int = (y_1s[j] - y_1s[i]) / (slopes[i] - slopes[j])

			if (t_int < t_min) and (t_int > 0):
				t_min = t_int
				x_min = slopes[i] * t_int + y_1s[i]
				i_min = i
				j_min = j

	# print first critical point
	print ("Critical Time  : %lf" % t_min)
	print ("Critical X     : %lf" % x_min)
	print ("Critical Path 1: %lft + %lf" % (slopes[i_min], y_1s[i_min]))
	print ("Critical Path 2: %lft + %lf" % (slopes[j_min], y_1s[j_min]))

	# plot char lines
	for i in range(0, num_lines):
		plt.plot([0, max_t], [y_1s[i], y_2s[i]])
	plt.show()


# solve the non linear transport equation. Solve via characteristics. The
# characteristic lines define where u is fixed value. 
def solver(max_t, n_t, min_x, max_x, n_x, f):
	xs = uniform(min_x, max_x, n_x)
	slopes = list(map(f,xs))
	ts = uniform(0, max_t, n_t)
	us = np.zeros((n_x))

	x_vals = np.zeros([n_t, n_x])

	# find the initial value of u at t = 0
	i = 0
	for x in xs:
		us[i] = f(x)
		i += 1

	# for each time step, compute the x-val where u is still constant.
	i = 0
	j = 0
	for t in ts:
		j = 0
		for x in xs:
			x_vals[i][j] = t*slopes[j] + x
			j += 1
		i += 1

	# for each time step transform x_val and us table into a array and sort
	i = 0
	for t in ts:
		plt.scatter(x_vals[i], us)
		plt.title("t = %lf" % t)
		plt.show()
		i+=1
	
 
#char_lines(math.sin, 1000,0, 10*math.pi, 10)
solver(5*math.pi, 20, 0.0*math.pi, 10.0*math.pi, 1000, lambda x: math.sin(x))