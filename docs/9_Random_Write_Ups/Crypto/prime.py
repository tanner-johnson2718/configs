# Lil number theory action
def gen_primes(n):
    ret = [2]
    for i in range(3,n+1):
        for p in ret:
            if i % p == 0:
                break
        if p == ret[-1]:
            ret.append(i)
    return ret

def prime_factors(n):
    pl = gen_primes(n)
    ret = []

    if(n < 2):
        return []

    while n != 1:
        for p in pl:
            if n % p == 0:
                ret.append(p)
                n = n / p
                break
    return ret