import matplotlib.pyplot as plt
import numpy as np

e = 0.25

def r(x):
    return 1/(1+e*np.cos(x))

def w(x):
    return (1+e*np.cos(x))*(1+e*np.cos(x))

def K(x):
    return e*e + 1 + 2*e*np.cos(x)

x1 = list(np.arange(0, 2*np.pi, .1))
r1 = list(map(r, x1))
w1 = list(map(w, x1))
k1 = list(map(K, x1))

e=.5
r2 = list(map(r, x1))
w2 = list(map(w, x1))
k2 = list(map(K, x1))

e=.75
r3 = list(map(r, x1))
w3 = list(map(w, x1))
k3 = list(map(K, x1))

fig, (ax1, ax2, ax3) = plt.subplots(3, 1)

ax1.plot(x1,r1, label = 'e=.25')
ax1.plot(x1,r2, label = 'e=.5')
ax1.plot(x1,r3, label = 'e=.75')
ax1.legend()
ax1.set_title("Radius 1/1+ecos(x)")

ax2.plot(x1,w1, label = 'e=.25')
ax2.plot(x1,w2, label = 'e=.5')
ax2.plot(x1,w3, label = 'e=.75')
ax2.legend()
ax2.set_title("Angular Velocity (1+ecos(x))^2")

ax3.plot(x1,k1, label = 'e=.25')
ax3.plot(x1,k2, label = 'e=.5')
ax3.plot(x1,k3, label = 'e=.75')
ax3.legend()
ax3.set_title("KE e^2 + 1 + 2ecos(x)")

plt.show()

# Now lets see if we can plot the actual ellipse
def r_x(x):
    return r(x)*np.cos(x)

def r_y(x):
    return r(x)*np.sin(x)

e = .25
rx1 = list(map(r_x,x1))
ry1 = list(map(r_y,x1))

e = .5
rx2 = list(map(r_x,x1))
ry2 = list(map(r_y,x1))

e = .75
rx3 = list(map(r_x,x1))
ry3 = list(map(r_y,x1))

fig, ax = plt.subplots()
ax.plot(rx1, ry1, label='e=.25')
ax.plot(rx2, ry2, label='e=.5')
ax.plot(rx3, ry3, label='e=.75')
ax.legend()
ax.grid(1)
ax.set_title('Orbits')
plt.show()