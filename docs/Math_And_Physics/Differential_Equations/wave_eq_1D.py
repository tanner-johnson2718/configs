# script contains functions for visuaulizing the 1D wave equation u_tt = c^2 u_xx + F(x,t)
# with u(0,x) = f(x) and u_t(0,x) = g(x). We will also assume no BD cond and
# will solve for x on the entire plane.

# solution and visualization using D'Alemberts solution i.e. u(t,x) = p(x-ct) + q(x+ct)
# in other words the solution is a superposition of a left and right ward moving standing wave

from util import uniform, moving_plot
import scipy.integrate as integrate
import math
import numpy as np

def solver(max_t, n_t, min_x, max_x, n_x, f, g, F, c):
	xs = uniform(min_x, max_x, n_x)
	ts = uniform(0, max_t, n_t)
	u = np.zeros((n_t, n_x))

	i = 0
	j = 0
	for t in ts:
		j = 0
		for x in xs:
			quad = integrate.quad(g, x - c*t, x + c*t)


			def lower(s):
				return x - c * (t-s)
			def upper(s):
				return x + c * (t-s)
			quad_F = integrate.dblquad(F, 0, t, lower, upper)


			u[i][j] = f(x - c*t) + f(x + c *t) + ((1.0 / (2.0 * c)) * (quad[0] + quad_F[0]))
			j += 1
		i+= 1

	moving_plot(u, xs, ts)

def f(x):
	return 0

def g(x):
	return 0

def F(x,t):
	return math.sin(2*t) * math.sin(x)


solver(10, 100, -10, 10, 100, f, g, F, 2)