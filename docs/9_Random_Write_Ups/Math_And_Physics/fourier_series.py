# script to vizualize the fourier series of functions.

import scipy.integrate as integrate
from util import moving_plot, uniform
import math
import numpy as np

# todo complex fourier series. diff and int of series, epicycles?

# given indicies and formula for series, print the partial sums
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