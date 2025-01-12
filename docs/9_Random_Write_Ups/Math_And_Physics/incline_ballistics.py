from scipy.optimize import fsolve
import math
import numpy as np
from matplotlib import pyplot as plt
from util import uniform, moving_plot

g = 9.8
v = 75.0
phi_g = math.pi / 4   # 45deg uphill

# the time it takes for the bullet to hit the ground
def t_hit(theta):
    return (2 * v * math.sin(theta)) / g

# the x-pos of the bullet when it hits the ground
def x_hit(theta):
    return   (2.0) / g * v * v * math.cos(theta) * math.sin(theta)

def pin_angle(x):
    def opt(theta):
        return x_hit(theta) - x
    return fsolve(opt, 0)

def t_rot_hit(theta):
    return t_hit(theta) / math.cos(phi_g)

def x_rot_hit(theta):
    return (v * math.cos(theta) * t_rot_hit(theta)) + ((g * math.sin(phi_g) / 2.0) * t_rot_hit(theta) * t_rot_hit(theta))


# create table of LOS and PHI values
n = 20
LOSs = uniform(0, 50, n)
PHIs = uniform(-50, 50, n)

table = np.zeros((n +1, n + 1))
table[0,0] = -1

i = 0
for los in LOSs:
    table[0, i+1] = los
    i += 1

i = 0
for phi in PHIs:
    table[i+1, 0] = phi
    i+=1

i = 0
j = 0
for phi in PHIs:
    j = 0
    phi_g = (phi / 360.0) * 2.0 * math.pi
    for los in LOSs:

        def opt(theta):
            return x_rot_hit(theta) - los

        
        theta = fsolve(opt, 0)
        x_adj = x_hit(theta)

        table[i+1, j+1] = round(x_adj, 2)
        j +=1
    i += 1

np.savetxt("ball_table.csv", table, delimiter=',')