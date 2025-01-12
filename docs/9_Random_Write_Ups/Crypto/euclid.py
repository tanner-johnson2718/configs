###############################################################################
# Euclidean Algorithm
###############################################################################
import matplotlib.pyplot as plt
import numpy as np

def gcd(a,b):
    if b == 0:
        return a
    return gcd(b, a%b)

def gcd_iter_tracking(a,b):
    n = 0
    while b > 0:
        n += 1
        t = b
        b = a % b
        a = t
    return a, n

def plot_gcd_iter():
    N_max = 100
    a_list = range(2,N_max)
    b_list = range(2,N_max)
    nmap = np.zeros((N_max,N_max))

    for a_in in a_list:
        for b_in in b_list:
            g,n = gcd_iter_tracking(a_in, b_in)
            nmap[a_in][b_in] = n

    fig, ax = plt.subplots()
    pcm = ax.pcolormesh(nmap)
    fig.colorbar(pcm)
    plt.show()

    max_val = 0
    index_max = [0,0]
    for i in range(0,N_max):
        for j in range(0,N_max):
            if nmap[i][j] > max_val:
                max_val = nmap[i][j]
                index_max[0] = i
                index_max[1] = j
    print("Max = " + str(max_val) + " at " + str(index_max))
    print
###############################################################################
# Extended Euclidean Algorithm
###############################################################################
# Solve a = 1 mod b and b =1 mod a <==>  n_a*a + n_b*b = 1
# return n_a, n_b or inv(a), inv(b) in mod the other variable
def modInverse(a, b):

    if b > a:
        n_b, n_a = modInverse(b, a)
        return n_a, n_b
    
    # Compute all the quotients using the same update rule as gcd: a becomes b
    # and b becomes a%b. 
    q = []
    while b > 1:
        q.append(a // b)
        a_old  = a
        b_old = b
        a = b_old
        b = a_old % b_old

    # See write up for details on the update step.
    n_a = 1
    n_b = -q.pop()
    while len(q) > 0:
        n_a_old = n_a
        n_b_old = n_b

        n_a = n_b_old
        n_b = n_a_old - (q.pop() * n_b_old)

    return n_a, n_b