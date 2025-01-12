from aes import *
import random

###############################################################################
# Challange 16
###############################################################################

print("\nChallange 16) ")

random.seed(69)
key = [random.randint(0,255) for i in range(0,16)]


def enc_oracle(in_str):
    if ';' in in_str:
        chunks = in_str.split(';')
        in_str = ""
        for i in range(0,len(chunks) - 1):
            in_str += (chunks[i] + "\";\"")
        in_str += chunks[-1]


    if '=' in in_str:
        chunks = in_str.split('=')
        in_str = ""
        for i in range(0,len(chunks) - 1):
            in_str += (chunks[i] + "\"=\"")
        in_str += chunks[-1]

    
    str1 = "comment1=cooking%20MCs;userdata="
    buff1 = ascii2buff(str1)
    str2 = ";comment2=%20like%20a%20pound%20of%20bacon"
    buff2 = ascii2buff(str2)
    in_buff = ascii2buff(in_str)

    blocks = blockify(buff1 + in_buff + buff2)

    return encrypt_cbc(key, blocks, [0]*16)

def check(ct_blocks):
    blocks = decrypt_cbc(key, ct_blocks,  [0]*16)

    data = unblockify(blocks)

    out_str = buff2ascii(data)

    print(out_str)

    if "admin=true" in out_str:
        print("ACCESS GRANTED")
    else:
        print("ACCESS DENIED")

# one bit error
ct_blocks = enc_oracle("?admin?true?")
ct_blocks[1][0] ^= 4
ct_blocks[1][6] ^= 2
ct_blocks[1][11] ^= 4
check(ct_blocks)