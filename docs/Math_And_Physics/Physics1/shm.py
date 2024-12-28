# SHM animation. i.e. show dynamics of a(t) = -(k/m) x(t). Show occilator,
# pos, vel, and accel as func of time, show K and U as func of time,

import matplotlib.pyplot as plt
import numpy as np
import matplotlib.animation as animation

# initial conditions
x_m = 1.0
k = 1.0
m = 1.0
w = np.sqrt(k/m)

# Time / simulation parameters
dt = .01
t_end = int(4*(2*np.pi / w))
t = np.arange(0,t_end, dt)

# Compute dynamics
x = list( map(lambda t : x_m*np.cos(w*t), t) )
v = list( map(lambda t : -1.0*w*x_m*np.sin(w*t), t) )
a = list( map(lambda t : -1.0*w*w*x_m*np.cos(w*t), t) )

K = list(map(lambda t : .5*m*w*w*x_m*x_m*np.sin(w*t)*np.sin(w*t), t))
U = list(map(lambda t : .5*k*x_m*x_m*np.cos(w*t)*np.cos(w*t), t))

fig2, ((ax), (ax2), (ax3)) = plt.subplots(3,1)

ax.grid(1)
ax.set_xlim(left=-x_m,right=x_m)
scat = ax.scatter(x[0], 0, s=50)
qF = ax.quiver([0], [0], [m*a[0]], [0], color='g')

ax2.set_ylim(bottom=-x_m*max(1,w,w*w),top=x_m*max(1,w,w*w))
ax2.set_xlim(left=0,right=t_end)
ax2.grid(1)
line2, = ax2.plot([], [], lw=3)
line2.set_label("Pos")
line3, = ax2.plot([], [], lw=3)
line3.set_label("Vel")
line4, = ax2.plot([], [], lw=3)
line4.set_label("Accel")
ax2.legend()

ax3.set_ylim(bottom=0,top=.5*k*x_m*x_m)
ax3.set_xlim(left=0,right=t_end)
ax3.grid(1)
line6, = ax3.plot([], [], lw=3)
line6.set_label("U")
line5, = ax3.plot([], [], lw=3)
line5.set_label("K")

ax3.legend()

def animate2(i):
    line2.set_data(t[0:i], x[0:i] )
    line3.set_data(t[0:i], v[0:i] )
    line4.set_data(t[0:i], a[0:i])
    line5.set_data(t[0:i], K[0:i])
    line6.set_data(t[0:i], U[0:i])
    scat.set_offsets((x[i], 0))
    qF.set_UVC([m*a[i]], [0])
    return (line2, line3,line4, line5, line6, scat, qF)

anim = animation.FuncAnimation(fig2, animate2, interval=5, blit=True)

plt.show()