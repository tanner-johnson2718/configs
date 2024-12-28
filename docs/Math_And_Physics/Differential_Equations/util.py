# utility scripts that contains useful function for vizualizing PDEs

from matplotlib import pyplot as plt
import math
import numpy as np
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
