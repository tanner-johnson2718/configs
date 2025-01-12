# Two Body Numerical Simulation

import numpy as np
import matplotlib.pyplot as plt
import matplotlib.animation as animation
import time
from scipy.integrate import quad

# State
x1 = np.zeros((3))
x2 = np.zeros((3))
v1 = np.zeros((3))
v2 = np.zeros((3))
a1 = np.zeros((3))
a2 = np.zeros((3))

###############################################################################

# initial conditions
m1 = 1000.1
m2 = 3.4

x1[0] = 0.0
x1[1] = 0.0
x1[2] = 0.0

x2[0] = 10.0
x2[1] = 0.0
x2[2] = 0.0

v1[0] = 0.0
v1[1] = 0.0
v1[2] = 0.0

v2[0] = 0.0
v2[1] = 10.00
v2[2] = 0.0

# constants
G = 1.0

# Numerical Parameters
dt = .001
t_end = 100
n_steps = int(t_end / dt)

# Animation Paramaters
animate_bool = 1
frame_skip = 10
x_min = -10
x_max = 10
y_min = -10
y_max = 10
z_min = -10
z_max = 10

# Stats
compute_stats = 1

###############################################################################

X1 = np.zeros((n_steps, 3))
V1 = np.zeros((n_steps, 3))
V2 = np.zeros((n_steps, 3))
X2 = np.zeros((n_steps, 3))

###############################################################################

# Define acceleration and radial vector
def dot(x1, x2):
    return x1[0]*x2[0] + x1[1]*x2[1] + x1[2]*x2[2]

def norm(r):
    return np.sqrt(dot(r,r))

def r(x1, x2):
    return x1 - x2

def a1_f(x1, x2, m1, m2):
    return (((-G) * m2) / pow(dot( r(x1,x2), r(x1,x2) ), 1.5) ) * r(x1, x2)

def a2_f(x1, x2, m1, m2):
    return (((G) * m1) / pow(dot( r(x1,x2), r(x1,x2)), 1.5) ) * r(x1, x2)

# define physical quantities
def p(m, v):
    return m*norm(v)

def l(r, m,v):
    return norm(np.cross(r,m*v))

def K(m, v):
    return 0.5 * m * dot(v,v)

def U(m1,m2, r):
    return -1.0 * m1 * m2 * G / r

# In reduced 1 body problem
def E_total(x1,x2,v1,v2,m1,m2):
    return K( (m1*m2) / (m1+m2), v1 - v2) + U(m1, m2, norm(r(x1,x2)))

# In reduced 1 body problem
def L_total(x1, x2, v1, v2, m1, m2):
    r0 = r(x1, x2)
    v = v1 - v2
    mu = (m1*m2) / (m1 + m2)

    return l(r0, mu, v)

def time_integrand(x, e):
    return pow(e*np.cos(x)+1, -2.0)


# Now we can run our main similation loop. Set a sufficiently small dt. Run simulation for time.
# Memoize all positions, velocities, and accels. Update state using simple linear differential calc.
# Plot path.

print("Initial Conditions: ")
print("    x1_0 = " + str(x1))
print("    x2_0 = " + str(x2))
print("    v1_0 = " + str(v1))
print("    v2_0 = " + str(v2))
print("    m1   = " + str(m1))
print("    m2   = " + str(m2))
print("    G    = " + str(G))
print("")
print("Generating Data...")

for i in range(0,n_steps):
    # update accel
    a1 = a1_f(x1, x2, m1, m2)
    a2 = a2_f(x1, x2, m1, m2)

    # update vel half step
    v1 = v1 + a1*dt/2.0
    v2 = v2 + a2*dt/2.0

    # update pos
    x1 = x1 + v1*dt
    x2 = x2 + v2*dt

     # update accel
    a1 = a1_f(x1, x2, m1, m2)
    a2 = a2_f(x1, x2, m1, m2)

    # update vel half step
    v1 = v1 + a1*dt/2.0
    v2 = v2 + a2*dt/2.0

    V1[i] = v1
    V2[i] = v2
    X1[i] = x1
    X2[i] = x2

print("Done.\n")

# Now let us analyze the data and commpare it to what our analysis predicts.
if(L_total(X1[i], X2[i], V1[i], V2[i], m1, m2) < .0000001):
        print("Degenerate case, close enough to 0 angular momentum detected. Will not compute stats.")
        compute_stats = 0

if compute_stats:

    

    # First let us verify that energy and angular momentum are conserved
    print("Calculating Conservation Stats...")
    min_E = E_total(X1[0], X2[0], V1[0], V2[0], m1, m2)
    max_E = min_E
    min_L = l(X1[0], m1, V1[0]) + l(X2[0], m2, V2[0])
    max_L = min_L
    E_avg = 0
    L_avg = 0
    K_min = np.inf
    K_max = 0
    for i in range(0,n_steps):
        E = E_total(X1[i], X2[i], V1[i], V2[i], m1, m2)
        L = L_total(X1[i], X2[i], V1[i], V2[i], m1, m2)
        K0 = K((m1 * m2) / (m1 + m2), V1[i] - V2[i])
        E_avg += E
        L_avg += L

        if E > max_E:
            max_E = E

        if E < min_E:
            min_E = E

        if L > max_L:
            max_L = L

        if L < min_L:
            min_L = L
        if K0 < K_min:
            K_min = K0
        if K0 > K_max:
            K_max = K0

    E_avg /= n_steps
    L_avg /= n_steps

    sigma_E = 0
    sigma_L = 0
    for i in range(0, n_steps):
        E = E_total(X1[i], X2[i], V1[i], V2[i], m1, m2)
        L = L_total(X1[i], X2[i], V1[i], V2[i], m1, m2)
        
        sigma_E += abs(E - E_avg)
        sigma_L += abs(L - L_avg)

    sigma_E /= n_steps
    sigma_L /= n_steps

    print("    Delta E = " + str(max_E - min_E))
    print("    Avg E   = " + str(E_avg))
    print("    Sigma E = " + str(sigma_E))
    print("    Delta L = " + str(max_L - min_L))
    print("    Avg L   = " + str(L_avg))
    print("    Sigma L = " + str(sigma_L))
    print("")

    # Next lets try to estimate from the data the eccentricity and compare that to what our analysis predicts
    # Do this also for the orbit and energy as they are related to the eccentricity
    print("Estimating Eccentricity, Energy, and orbit...")

    E = E_total(X1[i], X2[i], V1[i], V2[i], m1, m2)
    L = L_total(X1[i], X2[i], V1[i], V2[i], m1, m2)
    E_circ = (-1.0 / 2.0 ) * ( (m1*m2) / (m1 + m2)) * G * G * m1 * m1 * m2 * m2 * (1 / (L * L) )
    mu = (m1 * m2) / (m1 + m2)

    if E >= 0:
        print("    Non Capturing Orbit Predicted")
    elif E >= E_circ:
        print("    Stable Elliptical Orbit Predicted")
    else:
        print("    Falling Orbit Predicted")


    eccentricity_predicted = np.sqrt(1 + ((2 * E * L * L) / (mu * G * G * m1 * m1 * m2 * m2)))
    E_predicted = (((eccentricity_predicted * eccentricity_predicted) - 1) * mu * G * G * m1 * m1 * m2 * m2) / (2.0 * L * L)

    # Now need to estimate ecentricity. Eccentricty is what relates an angle to a radius. So,
    # to estimate look at two steps, find the angle traversed, and use the radius to calc e?
    e_min = 0
    for i in range(1, n_steps):
        r0 = r(X1[i-1], X2[i-1])
        r1 = r(X1[i], X2[i])

        cos_theta = (dot(r0, r1) / (norm(r0) * norm(r1)))
        R = (norm(r0) + norm(r1)) / 2.0
        e = ( ( (L*L) / (mu * G * m1 * m2 * R) ) -1) / cos_theta

        if e < e_min:
            e_min = e

    eccentricity_calc = - e_min

    K_max_predicted = ((mu * G * G * m1 * m1 * m2 * m2) / (2*L*L)) * (1+eccentricity_predicted)* (1+eccentricity_predicted)
    K_min_predicted = E_predicted
    if E < 0:
        K_min_predicted = ((mu * G * G * m1 * m1 * m2 * m2) / (2*L*L)) * (1-eccentricity_predicted)* (1-eccentricity_predicted)

    print("    Eccentricity Predicted   = " + str(eccentricity_predicted))
    print("    Eccentricity Calculated  = " + str(eccentricity_calc))
    print("    Energy Predicted         = " + str(E_predicted))
    print("    Energy Calculated        = " + str(E_avg))
    print("    K_max predicted          = " + str(K_max_predicted))
    print("    K_max Calculated         = " + str(K_max))
    print("    K_min predicted          = " + str(K_min_predicted))
    print("    K_min Calculated         = " + str(K_min))
    print("")

    # Next let's see if our predicted min and max radius make sense and maybe
    # try to fit our radius function to the data
    print("Checking Radial and Angular Velocity data...")
    R_min = np.inf
    R_max = 0
    w_min = np.inf
    w_max = 0
    for i in range(0,n_steps):
        R = norm(r(X1[i], X2[i]))
        w = norm(V1[i] - V2[i]) / R

        if R > R_max:
            R_max = R
        if R < R_min:
            R_min = R
        if w > w_max:
            w_max = w
        if w < w_min:
            w_min = w

    R_min_predicted = ((L * L) / (mu  * G  * m1  * m2)) / (1 + eccentricity_predicted)
    R_max_predicted = np.inf
    if E_predicted < 0:
        R_max_predicted = ((L * L) / (mu  * G  * m1  * m2)) / (1 - eccentricity_predicted)
    w_max_predicted = ((mu * G * G * m1 * m1 * m2 * m2) / (L*L*L)) * (1+eccentricity_predicted)* (1+eccentricity_predicted)
    w_min_predicted = 0
    if E_predicted < 0:
        w_min_predicted = ((mu * G * G * m1 * m1 * m2 * m2) / (L*L*L)) * (1-eccentricity_predicted)* (1-eccentricity_predicted)

    print("    R_min predicted  = " + str(R_min_predicted))
    print("    R_min calculated = " + str(R_min))
    print("    R_max predicted  = " + str(R_max_predicted))
    print("    R_max calculated = " + str(R_max))
    print("    w_max predicted  = " + str(w_max_predicted))
    print("    w_max Calculated = " + str(w_max))
    print("    w_min predicted  = " + str(w_min_predicted))
    print("    w_min Calculated = " + str(w_min))
    print("")

    # For elliptical orbit try to calc period
    if E_predicted < 0:
        print("Finding period of elliptical orbit...")

        R_eps = .5* abs(norm(X1[0] - X2[0]) - norm(r(X1[1], X2[1])))
        T_in_window = []
        for i in range(0, n_steps):
            R = norm(X1[i] - X2[i])
            if abs(R-R_max) < R_eps:
                T_in_window.append(i*dt)

        T_possible = []
        for i in range(1, len(T_in_window)):
            T_possible.append(T_in_window[i] -T_in_window[i-1])

        res, err = quad(lambda x : time_integrand(x, eccentricity_predicted), 0, 2*np.pi)
        T_predicted = (L*L*L) * res / (mu * G * G * m1 * m1 * m2 * m2)
        print("    Period Predicted  = " + str(T_predicted))
        print("    Period Calculated = " + str(max(T_possible)))
        print("")

    # Verify K(theta), w(theta), R(theta), and t(theta) formulas fit data

# plot Pos and Accels and create animation
if animate_bool:
    fig = plt.figure(0)
    ax = plt.axes(projection='3d')
    ax.axes.set_xlim3d(left=x_min, right=x_max) 
    ax.axes.set_ylim3d(bottom=y_min, top=y_max) 
    ax.axes.set_zlim3d(bottom=z_min, top=z_max)

    def animate(i):
        global ax

        i = frame_skip*i

        print("t = " + str(i*dt))

        if(i  >= n_steps):
            plt.close(fig)
            return

        a1 = a1_f(X1[i], X2[i], m1, m2)
        a2 = a2_f(X1[i], X2[i], m1, m2)

        ax.clear()
        ax.axes.set_xlim3d(left=x_min, right=x_max) 
        ax.axes.set_ylim3d(bottom=y_min, top=y_max) 
        ax.axes.set_zlim3d(bottom=z_min, top=z_max)
        ax.scatter3D([X1[i][0], X2[i][0]], [X1[i][1], X2[i][1]], [X1[i][2], X2[i][2]], s=100)
        ax.quiver([X1[i][0], X2[i][0]], [X1[i][1], X2[i][1]], [X1[i][2], X2[i][2]], [a1[0], a2[0]], [a1[1], a2[1]], [a1[2], a2[2]])

        return ax

    print("Animating...")
    time.sleep(1)
    ani = animation.FuncAnimation(fig, animate, interval=1)
    plt.show()