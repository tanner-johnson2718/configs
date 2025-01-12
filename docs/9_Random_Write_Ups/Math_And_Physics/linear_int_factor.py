# Script to play with solving first order linear ODE i.e. y' + P(x)y = Q(x).
# We want to use the product rule to turn the LHS into something like (y * I(x))'
# Example y' + (1/x)y = 2.
# Multiply through w/ x -> y'x +y = 2x
# Reverse product rule  -> (yx)' = 2x
# Integrate and solve -> y = x + C/x.
#
# So we postulate that for any ODE, there exist and integrating factor
# s.t. (y*I(x))' = I(x)Q(x).
# So expand y' * I + I'*y = IQ  ->  y' + I/I' y = Q  ->  I'/I = P
# Integrate both sides -> ln(I) = int P dx
# So I = e ^ int P dx.
# So solution is y = (1/I(x)) int Q(x)I(x)dx + C.

# Now in this script we wish to solve this using symbolic computation when possible.
# So our input will be a general linear first order ODE. We will compute and then plot
# the integrating factor, then compute and plot the solution. Maybe this will give us
# an idea of what this integrating factor is from a more geometric stand.
# The motivatino behind this is, while finding the soln is easy, this algorithm does not
# stick in the mind very easy.

import sympy as sym
import numpy as np
import matplotlib.pyplot as plt

sym.init_printing(use_unicode=False, wrap_line=False)

# Prompt Input
print('==================================================')
print("Linear First Order ODE Solver!")
print('Solve ODE of form y + P(x)y = Q(x)')
print('==================================================')
print("")
print("Enter P(x) i.e. x^2 + 2x - cos(x) + exp(x): ")
P_str = input()
print("Enter Q(x) (can't be 0): ")
Q_str = input()
print()

# Turn strings into expressions
x = sym.Symbol('x')
P_expr = sym.parse_expr(P_str)
Q_expr = sym.parse_expr(Q_str)

# Compute the integrating Factor
I = sym.exp( sym.integrate(P_expr, x) )
print("Integrating Factor: ")
print(I)
print()

# Compute the solution
y = (1/I) * sym.integrate(Q_expr * I, x)
print("Solution: ")
print(y)

# Plot
x_mesh = np.arange(1,10, .01)
y_func = sym.lambdify(x,y,"numpy")
y_mesh = y_func(x_mesh)
I_func = sym.lambdify(x,I,"numpy")
I_mesh = y_func(x_mesh)

fig, (ax1, ax2) = plt.subplots(2,1)
ax1.plot(x_mesh, y_mesh)
ax1.grid(1)
ax1.set_title('Solution')
ax2.plot(x_mesh, I_mesh)
ax2.grid(1)
ax2.set_title('Integrating Factor')
plt.show()