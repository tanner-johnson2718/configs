import random

def wt(a,b):
    x = ord(a) ^ ord(b)
    return bin(x).count("1")

def wt4(a,b,c,d):
    x = ord(a) ^ ord(b) ^ ord(c) ^ ord(d)
    return bin(x).count("1")

letter_freq = {'E' : 12.0,
'T' : 9.10,
'A' : 8.12,
'O' : 7.68,
'I' : 7.31,
'N' : 6.95,
'S' : 6.28,
'R' : 6.02,
'H' : 5.92,
'D' : 4.32,
'L' : 3.98,
'U' : 2.88,
'C' : 2.71,
'M' : 2.61,
'F' : 2.30,
'Y' : 2.11,
'W' : 2.09,
'G' : 2.03,
'P' : 1.82,
'B' : 1.49,
'V' : 1.11,
'K' : 0.69,
'X' : 0.17,
'Q' : 0.11,
'J' : 0.10,
'Z' : 0.07 }

N = sum(letter_freq.values())

# Comput the expected value of wt(A ^ B) where wt just counts the number of 1s
# in the binary representation where A and B are english letters according to
# distribution of english letters in english text
E2 = 0
for k1 in letter_freq.keys():
    for k2 in letter_freq.keys():
        E2 += letter_freq[k1]*letter_freq[k2]*wt(k1,k2)

E2 = E2 / (N*N)
print(E2)

# Comput the expected value of wt(A ^ B ^ X ^ Y) where wt just counts the 
# # number of 1s in the binary representation where A and B are english letters
# according to distribution of english letters in english text and X,Y are just
# uniformly random bytes
E4 = 0
for k1 in letter_freq.keys():
    for k2 in letter_freq.keys():
        for k3 in [chr(i) for i in range(0,256)]:
            for k4 in [chr(i) for i in range(0,256)]:
                E4 += letter_freq[k1]*letter_freq[k2]*wt4(k1,k2, k3,k4)

E4 = E4 / (N*N*256.0*256.0)
print(E4)