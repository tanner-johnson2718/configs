import matplotlib.pyplot as plt
import numpy as np

e = 1.0
eps = .1

def r(x):
    return 1/(1+e*np.cos(x))

def w(x):
    return (1+e*np.cos(x))*(1+e*np.cos(x))

def K(x):
    return e*e + 1 + 2*e*np.cos(x)

x1 = list(np.arange(-np.pi + eps, np.pi - eps, .05))
r1 = list(map(r, x1))
w1 = list(map(w, x1))
k1 = list(map(K, x1))


fig, (ax1, ax2, ax3) = plt.subplots(3, 1)

ax1.plot(x1,r1, label = 'e=1.0')
ax1.legend()
ax1.set_title("Radius")

ax2.plot(x1,w1, label = 'e=1.0')
ax2.legend()
ax2.set_title("Angular Velocity")

ax3.plot(x1,k1, label = 'e=1.0')
ax3.legend()
ax3.set_title("KE")

plt.show()

# Now lets see if we can plot the actual ellipse
def r_x(x):
    return r(x)*np.cos(x)

def r_y(x):
    return r(x)*np.sin(x)

e = 1.0
rx1 = list(map(r_x,x1))
ry1 = list(map(r_y,x1))

fig, ax = plt.subplots()
ax.plot(rx1, ry1, label='e=1.0')
ax.legend()
ax.grid(1)
ax.set_title('Orbits')
plt.show()