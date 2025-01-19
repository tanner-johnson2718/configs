# PDE

## Non Linear Transport Code

```python
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
```

## Fourier Code

```python
# script to vizualize the fourier series of functions.

import scipy.integrate as integrate
import math
import numpy as np
from matplotlib import pyplot as plt
from matplotlib.animation import FuncAnimation

# given matrix of values u(t,x) plot each row in an animated plot
# can also plot second matrix of values e, which represents the numerical
# error at that point in the (t,x) space
def moving_plot(u, xs, ts):
	fig = plt.figure()
	ax = fig.add_subplot(1,1,1)
	max_u = max( [max(row) for row in u])
	min_u = min( [min(row) for row in u])
	eps = (max_u - min_u) / 10

	def animate(i):
		ax.clear()	
		plt.axis([xs[0], xs[-1], min_u - eps, max_u + eps])
		plt.title("t = %lf" % ts[i])
		ax.plot(xs, u[i], scalex = False, scaley = False)
	
	
	a = FuncAnimation(fig, animate, frames=len(ts), repeat=False, interval=1000 * (ts[1] - ts[0]))
	plt.show()


# return 1D vector with n uniformly spaced points on [x,y)
def uniform(x, y, n):
    ys = []
    delta = (y - x) / n
    for i in range(0, n):
        ys.append(i * delta + x)
    return ys

# todo complex fourier series. diff and int of series, epicycles?

# given indicies and formula for series, print the partial srms
# in other words print sum_{i = i[0] to i[n]} s(i) for n = 1 to len(ind)
def series_comp(ind, b):
    sum = 0
    for i in ind:
        sum += b(i)
        print("i = %d b(i) = %lf s(i) = %lf" % (i, b(i), sum))

# return the first n coef of the sin series
def sin_coef(f, n):
    ret = []
    for k in range(1, n+1):
        def func(x):
            return f(x) * math.sin(k * x)
        
        quad = integrate.quad(func, -1.0 * math.pi, math.pi)
        ret.append((1.0 / math.pi) * quad[0])
    return ret
    

#return the first n coef of the cos series
def cos_coef(f,n):
    ret = []
    for k in range(1, n+1):
        def func(x):
            return f(x) * math.cos(k * x)
        
        quad = integrate.quad(func, -1.0 * math.pi, math.pi)
        ret.append( (1.0 / math.pi) * quad[0])
    return ret

# return the 1 vector coef, this is jus the mean of f over [-pi, pi]
def const_coef(f):
    quad = integrate.quad(f, -1.0* math.pi, math.pi)
    return (1.0 / (2.0 * math.pi)) * quad[0]

# n   = number of elements in fourier sequence
# n_x = number of points in mesh plotting function
def plot_fourier(f, n, n_x):
    a_k = cos_coef(f, n)
    b_k = sin_coef(f, n)
    m   = const_coef(f)
    xs = uniform(-1.0 * math.pi, math.pi, n_x)
    u = np.zeros((n+1, n_x))

    for i in range(0, n_x):
        u[0, i] = 0

    for k in range(1, n+1):
        x_ind = 0
        for x in xs:
            u[k, x_ind] = u[k-1, x_ind] + a_k[k-1] * math.cos(k* x) + b_k[k-1] * math.sin(k * x)
            x_ind += 1

    for k in range(1, n+1):
        x_ind = 0
        for x in xs:
            u[k, x_ind] += m

    moving_plot(u, xs, range(0, n+1))


plot_fourier(lambda x : x, 100, 100)
```
