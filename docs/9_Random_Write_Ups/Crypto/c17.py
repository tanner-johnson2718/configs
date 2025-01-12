from aes_cbc import *
import random

strings = [
        "This is a string so suck it bruh",
        "MDAwMDAxV2l0aCB0aGUgYmFzcyBraWNrZWQgaW4gYW5kIHRoZSBWZWdhJ3MgYXJlIHB1bXBpbic=",
        "MDAwMDAyUXVpY2sgdG8gdGhlIHBvaW50LCB0byB0aGUgcG9pbnQsIG5vIGZha2luZw==",
        "MDAwMDAzQ29va2luZyBNQydzIGxpa2UgYSBwb3VuZCBvZiBiYWNvbg==",
        "MDAwMDA0QnVybmluZyAnZW0sIGlmIHlvdSBhaW4ndCBxdWljayBhbmQgbmltYmxl",
        "MDAwMDA1SSBnbyBjcmF6eSB3aGVuIEkgaGVhciBhIGN5bWJhbA==",
        "MDAwMDA2QW5kIGEgaGlnaCBoYXQgd2l0aCBhIHNvdXBlZCB1cCB0ZW1wbw==",
        "MDAwMDA3SSdtIG9uIGEgcm9sbCwgaXQncyB0aW1lIHRvIGdvIHNvbG8=",
        "MDAwMDA4b2xsaW4nIGluIG15IGZpdmUgcG9pbnQgb2g=",
        "MDAwMDA5aXRoIG15IHJhZy10b3AgZG93biBzbyBteSBoYWlyIGNhbiBibG93"
        ]

buffs = []
for s in strings:
    buffs.append(ascii2buff(s))

key = [i for i in range(0,16)]
iv  = [85 for i in range(0,16)]

def e():
    index = random.randint(0, len(buffs) -1 )
    return encrypt_cbc(key,blockify(buffs[index]), iv)

def d(ct_blocks, this_iv):
    copy_ct = []
    tmp_b = []
    for ctb in ct_blocks:
        for b in ctb:
            tmp_b.append(b)
        copy_ct.append(tmp_b)
        tmp_b = []

    pt_blocks = decrypt_cbc(key, copy_ct, this_iv)
    last = pt_blocks[-1]

    pad = last[-1]
    good = []
    if pad > 16 or pad == 0:
        return 0

    for i in range(len(last)-1,len(last)-pad-1,-1):
        if last[i] == pad:
            good.append(1)
        else:
            break
    if sum(good) == pad:
        return 1
    return 0

ct_blocks = e()
answer = []
for block_index in range(0,len(ct_blocks)):
    
    target_block = ct_blocks[block_index]
    secret = [0] *16

    new_iv = [0 for i in range(0,16)]

    if block_index == 0:
        prev = iv
    else:
        prev = ct_blocks[block_index - 1]

    for byte_index in range(0,16):

        pad = byte_index + 1
        target_index = 15 - byte_index

        # update iv
        for i in range(16-byte_index, 16):
            new_iv[i] = secret[i] ^ prev[i] ^ pad

        for byte in range(0,256):
            new_iv[target_index] = byte

            if d([target_block], new_iv) == 1:
                found = byte ^ prev[target_index] ^ pad
                secret[target_index] = found
                print("Byte=" + str(byte) + " PREV=" + str(prev[target_index]) + " pad="+ str(pad) + " P=" + chr(found))

    answer.append(secret)


print(buff2ascii(unblockify(answer)))