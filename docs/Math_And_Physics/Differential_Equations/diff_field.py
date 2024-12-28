# Can be used to visualize things of the form dy/dx = F(y,x)

import matplotlib.pyplot as plt
import numpy as np
import itertools

# Generate mesh
x = list(np.arange(-2, 2, .2))
y = list(np.arange(-2, 2, .2))

X,Y = np.meshgrid(x,y)

# Set these to express and 1st order ODE i.e. dy/dx = F(x,y)
# As an example, this shows the differential field for y' = x^2 + y^2 -1
dx = np.ones(X.shape)
dy = X*X + Y*Y -1.0

fig, ax = plt.subplots()
ax.quiver(X,Y,dx,dy, headwidth=1.0, headlength=1.0)
ax.grid(1)
ax.set_title('Orbits')
plt.show()

fig, ax = plt.subplots()
ax.quiver(X,Y,dx,dy, headwidth=1.0, headlength=1.0)
ax.grid(1)
ax.set_title('Orbits')
plt.show()