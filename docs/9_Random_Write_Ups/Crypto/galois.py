# Take in any integer and convert it to an array of binary values
def galois_hex2binary(v):
    ret = []
    while v > 0:
        ret.insert(0,v & 1)
        v = v >> 1

    return ret

# Take in an array of binary values and return hex value
def galois_binary2hex(a):
    index = 0
    ret = 0

    # copy it so we dont mutate the input
    a_ = [v for v in a]

    while not len(a_) == 0:
        ret += (a_.pop() << index)
        index +=1
    return ret

def galois_equalize_len(a,b):
    if len(a) == len(b):
        return
    if len(a) > len(b):
        while len(b) != len(a):
            b.insert(0,0)
    if len(a) < len(b):
        while len(b) != len(a):
            a.insert(0,0)

# Take in 2 hex value polynimails and xor them i.e. their galois addition
def galois_add(a,b):
    return a ^ b

# Take in 2 hex value polynimials and return their polynomial multiplication
def galois_multi(a,b):
    ret = 0
    a_ = a
    b_ = b

    while a_ and b_:
        if a_ & 1: ret ^= b_
        a_ = a_ >> 1
        b_ = b_ << 1

    return ret

# Return the quotient and remainder of a/b. a and b are hex valued polys.
# assume b < a. Return q,r
def galois_euc_div(a,b):
    if b > a:
        print("galois_euc_div b > a")
        exit()

    q = 0
    a_ = a
    b_ = b

    while 1:
        shift = a_.bit_length() - b_.bit_length()
        if shift < 0: return q,a_
        q ^= (1 << shift)
        a_ = a_ ^ (b_ << shift)

# Return the poly that is the greatest common divison of the two hex format
# inputs
def galois_gcd(a,b):
    if b == 0:
        return a
    return galois_gcd(b, galois_euc_div(a,b)[1])

# This is the inverse function taken directly from euclid.py for computing the
# inverse of integers. All integer arithmetic has been replaced with poly 
# arthmetic over GF(2^q)
def galois_inv(a, b):
    if b > a:
        n_b, n_a = galois_inv(b, a)
        return n_a, n_b
    
    # Compute all the quotients using the same update rule as gcd: a becomes b
    # and b becomes a%b. 
    q = []
    while b > 1:
        q.append(galois_euc_div(a,b)[0])
        a_old  = a
        b_old = b
        a = b_old
        b = galois_euc_div(a_old,b_old)[1]

    # See write up for details on the update step.
    n_a = 1
    n_b = q.pop()
    while len(q) > 0:
        n_a_old = n_a
        n_b_old = n_b

        n_a = n_b_old
        n_b = galois_add(n_a_old,(galois_multi(q.pop(),n_b_old)))

    return n_a, n_b

a = 0xA0
b = 0x011b
a_,b_= galois_inv(a,b)

print(hex(a) + "   " + hex(a_) + "   " + hex(galois_multi(a,a_)))
print(hex(b) + "   " + hex(b_) + "   " + hex(galois_multi(b,b_)))