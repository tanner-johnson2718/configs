# We break AES EBC mode. Based on challanges from crypto pals

import random
import sys
from aes import *

###############################################################################
# Challange 11
###############################################################################

print("\nChallange 11)")
def rand_enc(data):
    key = [random.randint(0,255) for i in range(0,16)]

    # pad with random
    for i in range(0,random.randint(5,10)):
        data.insert(0, random.randint(0,255))
        data.append(random.randint(0,255))

    while ((len(data) % 16) != 0):
        data.append(4)

    tmp_block = []
    blocks = []
    counter = 0
    for i in range(0,len(data)):
        tmp_block.append(data[i])
        counter += 1
        if (counter == 16):
            blocks.append(tmp_block)
            tmp_block = []
            counter = 0

    if random.randint(0,1):
        #cbc
        print("CBC")
        iv = [random.randint(0,255) for i in range(0,16)]
        ct = encrypt_cbc(key, blocks, [0]*16)
        return ct
    else:
        #ecb
        print("ECB")
        ct = []
        for i in range(0, len(blocks)):
            ct.append(encrypt(key, blocks[i]))
        return ct

data = [69] * 48
ct = rand_enc(data)
t_table = [ct[1][j] == ct[2][j] for j in range(0,16)]
if sum(t_table) == 16:
    print("ECB")
else:
    print("CBC")
print

###############################################################################
# Challange 12
###############################################################################

print("Challange 12) ")

def encryption_service(data):
    # produce same key every call
    random.seed(0)
    key = [random.randint(0,255) for i in range(0,16)]

    # Now this is the secret we wish to find out
    str_b64 = "Um9sbGluJyBpbiBteSA1LjAKV2l0aCBteSByYWctdG9wIGRvd24gc28gbXkgaGFpciBjYW4gYmxvdwpUaGUgZ2lybGllcyBvbiBzdGFuZGJ5IHdhdmluZyBqdXN0IHRvIHNheSBoaQpEaWQgeW91IHN0b3A/IE5vLCBJIGp1c3QgZHJvdmUgYnkK"
    bytes_hex = base64_2hex(str_b64)

    # concatenate data with secret string
    cat = data + bytes_hex

    # blockify and encrypt
    blocks = blockify(cat)

    ct_blocks = []
    for i in range(0, len(blocks)):
        ct_blocks.append(encrypt(key, blocks[i]))

    return ct_blocks


# First we feed our encryption service single bytes until we hit the block 
# size + 1, this should tell us the block size... we know its 16
block_size = 16

# Next we would feed it several blocks worth of identical data and see if it
# produces the same cypter text. This tells us the service is using ECB.

# Now suppose our encryption service is appending some secret key to the end
# of the data we send it and we want find this out. We can preform a byte by
# byte attack.

# first send an empty data block to determine how long the secret string is
num_blocks = len(encryption_service([]))
if 0:
    secret = []
    se = b""
    for block_index in range(0,num_blocks):

        index_of_insertion = ((block_index+1)*block_size) -1

        for byte_index in range(0,16):

            input_ = [0] * (15-byte_index)
            key_buff = encryption_service(input_)[block_index]
            key_string = buff2ascii(key_buff)

            for i in range(10, 128):

                # Build test buffer
                test = [s for s in secret]
                while len(test) < index_of_insertion:
                    test.insert(0,0)
                test.append(i)

                ct_blocks = encryption_service(test)
                key_found = buff2ascii(ct_blocks[block_index])

                if key_string == key_found:
                    secret.append(i)
                    se += chr(i)
                    break
        print("Block Broken...")

    print(se)
else:
    print("Skipping challange 12 ..  takes too long to compute")

###############################################################################
# Challange 13
###############################################################################

print("\nChallange 13) ")

# assume we have a profile creation service that takes in an email, encodes it
# in key-val str with the following format: email=foo@bar.com&uid=7&role=user
# This string is encrypted and stored say in a cookie locally on a users pc.
# We know it uses AES-128 ECB, the block size, uid will be 1 digit, and unknown
# key. Using only calls to the profile creation service, find am encrypted text
# that decrypts and expands to an key val str with admin priviledges

def profile_for(email):
    if '=' in email or '&' in email:
        print("error")
        exit()

    string = "email="+email+"&uid=0&role=user"
    blocks = blockify(ascii2buff(string))

    random.seed(69)
    key = [random.randint(0,255) for i in range(0,16)]

    ct_blocks = []
    for i in range(0,len(blocks)):
        ct_blocks.append(encrypt(key, blocks[i]))

    return ct_blocks

def parse_ct(ct_blocks):
    random.seed(69)
    key = [random.randint(0,255) for i in range(0,16)]

    blocks = []
    for i in range(0,len(ct_blocks)):
        blocks.append(decrypt(key, ct_blocks[i]))

    string = buff2ascii(unblockify(blocks))

    dic = {}
    fields = string.split('&')
    for f in fields:
        key,val = f.split('=')
        dic[key] = val

    return dic

# lets sent email such that we have a block of "admin" padded by null chars
# alone by itself in a block
email_admin_blk = buff2ascii([0]*10) + "admin" + buff2ascii([0]*11)
admin_ct_block = profile_for(email_admin_blk)[1]

# Now craft an email of lenght so that the block cuts off at role=. With the
# last block containing the "user" portion:
# | email=fake_email | @cat&uid=0&role= | user
hacked_profile_ct_blocks = profile_for("fake_email@cat")
hacked_profile_ct_blocks[2] = admin_ct_block
print(parse_ct(hacked_profile_ct_blocks))

###############################################################################
# Challange 14
###############################################################################

print("\nChallange 14) ")

if 1:
    random.seed(420)
    key = [random.randint(0,255) for i in range(0,16)]
    def encryption_service2(data):

        # Now this is the secret we wish to find out
        str_b64 = "Um9sbGluJyBpbiBteSA1LjAKV2l0aCBteSByYWctdG9wIGRvd24gc28gbXkgaGFpciBjYW4gYmxvdwpUaGUgZ2lybGllcyBvbiBzdGFuZGJ5IHdhdmluZyBqdXN0IHRvIHNheSBoaQpEaWQgeW91IHN0b3A/IE5vLCBJIGp1c3QgZHJvdmUgYnkK"
        bytes_hex = base64_2hex(str_b64)

        rand_prefix = [random.randint(0,255) for i in range(0, random.randint(1,16))]
    
        # concatenate data with secret string
        cat = rand_prefix + data + bytes_hex

        # blockify and encrypt
        blocks = blockify(cat)

        ct_blocks = []
        for i in range(0, len(blocks)):
            ct_blocks.append(encrypt(key, blocks[i]))

        return ct_blocks

    # To make it somewhat easier we assume that ther is a min of 1 and a max of 16
    # aka one block of random prefix data. This implies there should be an input st
    # repeated calls to the encryption oracle yield a constant number of blocks 
    # returned. We can use this to find out the exact number of bytes in our hidden
    # string. This also gives us a criticial input size i.e. the one producing const
    # block size which implies thier are exactly block size # random bytes
    dic = {}
    for size in range(0,16):
        l = []
        for i in range(0,100):
            l.append(len(encryption_service2([0]*size)))

        if min(l) == max(l):
            dic[size] = max(l)

    print(dic)
    block_size = 16
    num_crit = dic.keys()[0]
    num_secret_bytes = ((dic.values()[0] - 1)*block_size) - num_crit
    print("Crit = " + str(num_crit) + " Sec = " + str(num_secret_bytes))

    # build a dictionary
    dic = {}
    secret = []
    for block_index in range(0,8):
        for byte_index in range(0,block_size):
            for i in range(0,256):
                # Create sus test block, encrypt till we get the case of the last block
                # containing only our target bytes
                test = [i] + secret + [block_size-1]*(block_size-1) + [num_crit+1]*(num_crit+1)
                while 1:
                    ct_blocks = encryption_service2(test)
                    k = buff2ascii(ct_blocks[-(block_index+1)])
                    if len(ct_blocks) == (12+block_index) and not k in dic.keys():
                        break
                
                dic[buff2ascii(ct_blocks[1])] = i

                if k in dic.keys():
                    print("Parsed: " + str(dic[k]))
                    secret.insert(0,i)
                    break
        print("Block Broken...")
    print(buff2ascii(secret))
else:
    print("takes to long to compute ... skipping")