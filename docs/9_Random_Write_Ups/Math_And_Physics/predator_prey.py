import matplotlib.pyplot as plt
import numpy as np
from matplotlib.widgets import Slider, Button
import matplotlib.animation as animation

# Lokta Volterra i.e. predator prey model
# dR/dt = kR - aRW and dW/dt = -rW + bRW
# R(t) is the rabbit population
# W(t) is the wolf population
# Assume that the # of encounters i.e. number of times a wolf eats a rabbit is proportional to RW (each population)
# Then a factor of -aRW is added to the delta of rabbits cause they get eaten
# And a factor pf +bRW is added to the wolves cause they eat and reproduce more wolves.

# So let us define the constants
k = .5     # k in our model. How fast the exponential growth of the rabbits are absent the wolves
                  # The units of this are births per rabbit per unit time

r = .5     # r in our model. How fast the wolves die off in the absence of food. 
                  # The units are wolf deaths per wolf per unit time

a = .5 # a in our model. This is just how many times a rabbit encounters i.e. gets eaten by a wolf per unit time
                       # units our rabbit deaths per wolf per rabbit per unit time

b = .5 # b in our model. The number of births a single rabbit eaten leads too.
                              # units are wolf births per eaten rabbit per unit time


# The first thing we can compute is the steady state solution. i.e. where does dR/Dt and dW/dt = 0?
# So dR/dt = kR - aRW = 0 and dW/dt = -rW + bRW = 0  ->  R(k - a W) = 0 and W(-r + bR) = 0
# And W = k/a   and   R = r/b
def compute_equil(k,a,r,b):
    W_equil = k / a
    R_equil = r / b
    return W_equil, R_equil
W_equil,R_equil = compute_equil(k,a,r,b)
print('Wolf Equil = ' + str(W_equil))
print('Rabb Equil = ' + str(R_equil))

# So the next thing we can do is a phase plane analysis. That is, look at the ratio dW/dR for various pairs (R,W).
# That is simply the expression dW/dR = (dW/dt) / (dR/dt) = (kR - aRW) / (-rW + bRW). Easy, now let's just generate
# a mesh to view this. We will associate wolves with the y-axis and rabbits with the x-axis.

# Numeric parameters
epsilon = .0000001
n_mesh = 25
window_percent = .95
norm_dir_field_vectors = 1

def compute_mesh(R_equil, W_equil):
    
    # Mesh limits
    x_min = R_equil - window_percent*R_equil
    x_max = R_equil + 3*window_percent*R_equil
    y_min = W_equil - window_percent*W_equil
    y_max = W_equil + 3*window_percent*W_equil
    x_step = (x_max - x_min) / n_mesh
    y_step = (y_max - y_min) / n_mesh

    # Generate mesh
    R_steps = list(np.arange(x_min, x_max, x_step))
    W_steps = list(np.arange(y_min, y_max, y_step))
    R_mesh,W_mesh = np.meshgrid(R_steps,W_steps)

    return R_mesh, W_mesh

R_mesh, W_mesh = compute_mesh(R_equil, W_equil)

# Compute the differntial field using scaling smoothing
def compute_dir_field(R_mesh, k , a, W_mesh, r, b ):
    # Initially compute differentials with dR = 1
    dR = np.ones(R_mesh.shape)
    dW =  (((-r * W_mesh) + (b * R_mesh * W_mesh)) ) / (((k * R_mesh) - (a * R_mesh * W_mesh)) + epsilon)

    # Now this will produce vectors of drastically different length, so normalize each vector
    if norm_dir_field_vectors:
        for i in range(0, R_mesh.shape[0]):
            for j in range(0, R_mesh.shape[1]):
                l = np.sqrt(1 + (dW[i][j]*dW[i][j]))
                dR[i][j] = dR[i][j] / l
                dW[i][j] = dW[i][j] / l 

    return dW, dR
dW,dR = compute_dir_field(R_mesh, k , a, W_mesh, r, b )

# Plot
fig, ax = plt.subplots()
quiver = ax.quiver(R_mesh,W_mesh,dR,dW, headwidth=1.1, headlength=1.0, width=.0015)
ax.grid(1)
ax.set_title('Predator / Prey i.e. dR/dt = kR - aRW and dW/dt = -rW + bRW')
ax.set_ylabel("N Wolves, Equil = " + str(W_equil))
ax.set_xlabel("N Rabbits, Equil = " + str(R_equil))

# Now we want to create 4 sliders for each of our parameters that affect the direction field
plt.subplots_adjust(left=0.25, bottom=0.25)

# Vertical slider for wolf death rate i.e. r
axamp = plt.axes([0.08, 0.25, 0.0225, 0.63])
r_slider = Slider(
    ax=axamp,
    label="Death Rate (r)",
    valmin=0,
    valmax=1,
    valinit=r,
    orientation="vertical"
)

# Vertical slider for wolf birth rate i.e. r
axamp = plt.axes([0.16, 0.25, 0.0225, 0.63])
b_slider = Slider(
    ax=axamp,
    label="Birth Rate (b)",
    valmin=0,
    valmax=1,
    valinit=b,
    orientation="vertical"
)

# Make a horizontal slider to control the Carrying Capacity.
axfreq = plt.axes([0.25, 0.08, 0.65, 0.03])
k_slider = Slider(
    ax=axfreq,
    label='Birth Rate (k)',
    valmin=0,
    valmax=1,
    valinit=k,
)

# Make a horizontal slider to control the Carrying Capacity.
ax2 = plt.axes([0.25, 0.16, 0.65, 0.03])
a_slider = Slider(
    ax=ax2,
    label='Death Rate (a)',
    valmin=0,
    valmax=1,
    valinit=a,
)

# Now lets compute the solution. So we have dR/dt = R(k - aW) and dW/dt = -W(r - bR).
# Lets set dR / R(k - aW) = dt  and    dW / -W(r - bR) = dt. 
# So (dW / dR) = - (W/R) * ( (bR - r) / (aW - k) )
# Rewriting:  (dW/W) (aW - k) = -(dR/R) * (bR - r)
# Rewriting:  (a - k/W)dW + (b - r/R)dR = 0
# Solving : aW - k ln(W) + bR - r ln(R) = C
# C will take on some prescribed value for an initial number of wolves and rabbits.

# Unfortunately, the above is not solvable explitily so we simply uses Euler's Method to
# compute a solution. So start again with dR/dt = R(k - aW) and dW/dt = -W(r + bR).
# Let R_1 = R_0 + (dR/dt)(R_0,W_0)*t_e and W_1 = W_0 + (dR/dt)(R_0, W_0)*t_e.
# Simply iterate this loop for small dt

# Init parameteres
W_0 = W_equil * (1.25)
R_0 = R_equil * (.30)
end_time = 1000
t_ep = .1
points_to_show = 100
n_pts = int(end_time / t_ep)

def compute_soln(R_0, W_0, a, b, k, r):
    def dR_dt(R,W):
        return R*(k - a*W)

    def dW_dt(R,W):
        return -W*(r - b*R)

    W_t = np.zeros(int(n_pts))
    R_t = np.zeros(int(n_pts))

    W_t[0] = W_0
    R_t[0] = R_0

    for i in range(0,n_pts - 1):
        W_t[i+1] = W_t[i] + dW_dt(R_t[i],W_t[i])*t_ep
        R_t[i+1] = R_t[i] + dR_dt(R_t[i],W_t[i])*t_ep

    # Reduce size to improve visualization
    

    return R_t, W_t

R_t, W_t = compute_soln(R_0, W_0, a, b, k, r)

a_prev = a
b_prev = b
r_prev = r
k_prev = k

line, = ax.plot(R_t[0:points_to_show], W_t[0:points_to_show])
def animate(i):
    global a_prev
    global b_prev
    global r_prev
    global k_prev
    global line
    global R_t
    global W_t

    a = a_slider.val
    b = b_slider.val
    k = k_slider.val
    r = r_slider.val

    # Update mesh and dir field only if one of the params changes
    if not ( (a_slider.val == a_prev) and (b_slider.val == b_prev) and (r_slider.val == r_prev) and (k_slider.val == k_prev) ):
        # Update Soln
        W_equil,R_equil = compute_equil(k,a,r,b)
        W_0 = W_equil * (1.25)
        R_0 = R_equil * (.30)
        R_t, W_t = compute_soln(R_0, W_0,a,b,k,r)

        # Update Mesh
        R_mesh, W_mesh = compute_mesh(R_equil, W_equil)
        dW,dR = compute_dir_field(R_mesh, k , a, W_mesh, r, b )

        # update dir field
        ax.clear()
        quiver = ax.quiver(R_mesh,W_mesh,dR,dW, headwidth=1.1, headlength=1.0, width=.0015)
        ax.grid(1)
        ax.set_title('Predator / Prey i.e. dR/dt = kR - aRW and dW/dt = -rW + bRW')
        ax.set_ylabel("N Wolves, Equil = " + str(W_equil))
        ax.set_xlabel("N Rabbits, Equil = " + str(R_equil))

        # Create new soln line cause we wiped it
        line, = ax.plot(R_t[0:points_to_show], W_t[0:points_to_show])

    # Update the line every pass
    line.set_xdata(R_t[(i % n_pts) : ((points_to_show + i ) % n_pts)])
    line.set_ydata(W_t[(i % n_pts) : ((points_to_show + i ) % n_pts)])
    
    a_prev = a_slider.val
    b_prev = b_slider.val
    r_prev = r_slider.val
    k_prev = k_slider.val

    return ax,
ani = animation.FuncAnimation(fig, animate, interval=1)

plt.show()