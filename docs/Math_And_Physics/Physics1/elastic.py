# Elastic Model) Model a string as a series of point masses connected by
# Springs with constant string stiffness. We will approximate the dynamics
# such that a mass only feels it two neighbors and is of course only free
# to move in the dir. Also use the approximation that F = -k dy

# Weirdness: If you calc U as U = .25 * k * dy^2 then you get conservatoin of energy?

import matplotlib.pyplot as plt
import numpy as np
import matplotlib.animation as animation
from time import sleep

# Params
N_nodes = 50
dt = .01
dx = .1
t_end = 100
L = dx * N_nodes
N_iter = int(t_end / dt)
m_node = 1.0
k = .5            # spring stiffness
fixed_BD = 1

# The update function to calculate the upwards or downward accel of a mass.
# Assumes F = -kdy
def calc_accel1(y, i, j):
    # calculate differnce forward
    dy_forward = 0
    if not j == N_nodes-1:
        dy_forward = y[i-1][j] - y[i-1][j+1]

    # calculate backward difference
    dy_backward = 0
    if not j == 0:
        dy_backward = y[i-1][j] - y[i-1][j-1]

    # Calculate force
    F_forward  = -1.0*k*(dy_forward)
    F_backward = -1.0*k*(dy_backward)

    # For fixed boundary conditions, the outer nodes feel no acceleration
    if fixed_BD and (j==0 or j==N_nodes-1):
        return 0

    # Update accel
    return (F_backward + F_forward) / m_node

# The update function to calculate the upwards or downward accel of a mass.
# Assumes F = -k (dl - dx) (dy/dl)
def calc_accel2(y, i, j):
    # calculate differnce forward
    dy_forward = 0
    if not j == N_nodes-1:
        dy_forward = y[i-1][j] - y[i-1][j+1]

    # calculate backward difference
    dy_backward = 0
    if not j == 0:
        dy_backward = y[i-1][j] - y[i-1][j-1]

    # Calculate size of stretched segment
    dl_forward = np.sqrt(dx*dx + dy_forward*dy_forward)
    dl_backward = np.sqrt(dx*dx + dy_backward*dy_backward)

    # Calculate force
    F_forward  = -1.0*k*(dl_forward - dx) * dy_forward / dl_forward
    F_backward = -1.0*k*(dl_backward - dx) * dy_backward / dl_backward

    # For fixed boundary conditions, the outer nodes feel no acceleration
    if fixed_BD and (j==0 or j==N_nodes-1):
        return 0

    # Update accel
    return (F_backward + F_forward) / m_node

def f_init(x):
    return 2.0*np.sin(2 * np.pi * x / L)

def g_init(x):
    return 0

# Set the initial wave form, will not use generator to drive wave
y_init = np.zeros(N_nodes)
for i in range(0,N_nodes):
    y_init[i] = (f_init(i*dx))

# Set the initial velocity at each point.
v_init = np.zeros(N_nodes)
for i in range(0, N_nodes):
    v_init[i] = g_init(i*dx)

# Run the simulation. For each point in time, and for each point, calculate the force on each particle
# due to its neighbor, then simulate the dynamics from there.

y = list()
v = list()
y.append(y_init)
v.append(v_init)

U = np.zeros(N_iter)
K = np.zeros(N_iter)
E = np.zeros(N_iter)

for i in range(1, N_iter):
    y.append(np.zeros(N_nodes))
    v.append(np.zeros(N_nodes))

    # Calc last iters U and K
    for j in range(0, N_nodes):
        K[i] += .5 * m_node * v[i-1][j]*v[i-1][j]

        dy = 0
        if not j == 0:
            dy = y[i-1][j] - y[i-1][j-1]

        U[i] += .5 * k * (dy*dy)
        E[i] = K[i]+U[i]

    # Calc new pos and vel
    for j in range(0, N_nodes):
        # Update accel
        a = calc_accel1(y, i, j)

        # velocity update
        v[i][j] += v[i-1][j] + (a * dt)

        # Pos update
        y[i][j] += y[i-1][j] + (v[i][j] * dt)

# Animate
x = np.zeros(N_nodes)
for i in range(0, N_nodes):
    x[i] = i*dx

t = np.zeros(N_iter)
for i in range(0, N_iter):
    t[i] = i*dt

fig, ((ax), (ax2)) = plt.subplots(2,1)

ax.set_ylim(bottom=-1,top=1)
ax.set_xlim(left=0,right=L)
scat = ax.scatter(x, y[0])
ax.grid(1)

ax2.set_ylim(bottom=0,top=max(E)+.1)
ax2.set_xlim(left=0,right=t_end)
lineU, = ax2.plot([], [])
lineU.set_label('U')
lineK, = ax2.plot([],[])
lineK.set_label('K')
lineE, = ax2.plot([], [])
lineE.set_label('E')
ax2.legend()

def animate(i):
    scat.set_offsets(np.c_[x,y[i]])
    lineU.set_data(t[0:i], U[0:i])
    lineK.set_data(t[0:i], K[0:i])
    lineE.set_data(t[0:i], E[0:i])
    return scat, lineU, lineK, lineE, 

anim = animation.FuncAnimation(fig, animate, interval=5, blit=True)
plt.show()