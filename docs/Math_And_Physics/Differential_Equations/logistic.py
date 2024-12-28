import matplotlib.pyplot as plt
import numpy as np
from matplotlib.widgets import Slider, Button

# Mesh limits
x_min = 0
x_max = 10
y_min = 0
y_max = 10
x_step = .4
y_step = .4

# Logistic equation paramteres
k = .4                      # growth rate
M = (y_max + y_min) / 2.0   # Population cap

# Generate mesh
x = list(np.arange(x_min, x_max, x_step))
y = list(np.arange(y_min, y_max, y_step))

X,Y = np.meshgrid(x,y)

# Find the direction field correspoding to the logisitic eq: dp/dt = kP(1 - P/k)
# This shows the trajectory of the system over all possible inputs
dt = np.ones(X.shape)

def compute_dir_field(Y, k, M):
    return (k*Y * (1 - Y/M))
dy = compute_dir_field(Y, k, M)

# Choose an initial solution and plot that specific path in the dir field
# soln is given by P(t) = M / (1 + Ae^-kt) where A = M-P_0 / P_0
P_0 = y_min + ((y_max - y_min) / 5.0)
def compute_soln(t, M, P_0, k):
    def P(t):
        A = (M - P_0) / P_0
        return M / (1.0 + (A*pow(np.e, -1.0*k*t)))

    return list(map(P, t))
    
P_soln = compute_soln(x, M, P_0, k)

# Create our initial plot with our init soln and dir. field
fig, ax = plt.subplots()
quiver = ax.quiver(X,Y,dt,dy, headwidth=1.0, headlength=1.0)
line, = plt.plot(x, P_soln)
ax.grid(1)
ax.set_title('Log. Eqn.')

# Make a vertically oriented slider to control the initial population
plt.subplots_adjust(left=0.25, bottom=0.25)
axamp = plt.axes([0.1, 0.25, 0.0225, 0.63])
init_pop_slider = Slider(
    ax=axamp,
    label="Init Pop",
    valmin=y_min,
    valmax=y_max,
    valinit=P_0,
    orientation="vertical"
)

# Make a horizontal slider to control the Carrying Capacity.
axfreq = plt.axes([0.25, 0.08, 0.65, 0.03])
cap_slider = Slider(
    ax=axfreq,
    label='Carrying Capacity',
    valmin=y_min,
    valmax=y_max,
    valinit=M,
)

# Make a horizontal slider to control the Carrying Capacity.
ax2 = plt.axes([0.25, 0.16, 0.65, 0.03])
growth_rate_slider = Slider(
    ax=ax2,
    label='Growth Rate',
    valmin=0,
    valmax=5,
    valinit=k,
)

# The function to be called anytime a slider's value changes
def update_plot(val):
    P_0 = init_pop_slider.val
    M = cap_slider.val
    k = growth_rate_slider.val

    # recompute the soln
    P_soln = compute_soln(x, M, P_0, k)

    # upate the dir field
    dy = compute_dir_field(Y, k, M)

    # replot
    quiver.set_UVC(dt, dy)
    line.set_ydata(P_soln)
    fig.canvas.draw_idle()

# register the update function with each slider
init_pop_slider.on_changed(update_plot)
cap_slider.on_changed(update_plot)
growth_rate_slider.on_changed(update_plot)

plt.show()