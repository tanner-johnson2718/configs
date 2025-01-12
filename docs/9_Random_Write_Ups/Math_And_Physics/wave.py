# Wave animation

import matplotlib.pyplot as plt
import numpy as np
import matplotlib.animation as animation

# initial conditions
k = 2.0
w = 2.0
x_m = 10.0

# wave form)
def h(s):
    if s > -10 and s < -9:
        return .5
    return 0

# Time, Space / simulation parameters
dt = .01
dx = .01
t_end = 1000
t = np.arange(0,t_end, dt)
x = np.arange(-x_m,x_m, dx)

# Compute dynamics
y = []
for i in range(0, t_end):
    y.append(list(map(lambda x: h(k*x - w*t[i]), x)))

# Animate
fig, ((ax)) = plt.subplots(1,1)
ax.set_ylim(bottom=-1,top=1)
ax.set_xlim(left=-x_m,right=x_m)
line, = ax.plot([], [], lw=3)
ax.grid(1)

def animate(i):
    line.set_data(x, y[i])
    return line, 

anim = animation.FuncAnimation(fig, animate, interval=5, blit=True)
plt.show()
