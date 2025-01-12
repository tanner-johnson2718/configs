# AES-128  cipher block chaining, counter, and EBC modes

###############################################################################
# AES-128 CBC common private
###############################################################################

S   = [  0x63, 0x7c, 0x77, 0x7b, 0xf2, 0x6b, 0x6f, 0xc5, 0x30, 0x01, 0x67, 
         0x2b, 0xfe, 0xd7, 0xab, 0x76, 0xca, 0x82, 0xc9, 0x7d, 0xfa, 0x59, 
         0x47, 0xf0, 0xad, 0xd4, 0xa2, 0xaf, 0x9c, 0xa4, 0x72, 0xc0, 0xb7, 
         0xfd, 0x93, 0x26, 0x36, 0x3f, 0xf7, 0xcc, 0x34, 0xa5, 0xe5, 0xf1, 
         0x71, 0xd8, 0x31, 0x15, 0x04, 0xc7, 0x23, 0xc3, 0x18, 0x96, 0x05, 
         0x9a, 0x07, 0x12, 0x80, 0xe2, 0xeb, 0x27, 0xb2, 0x75, 0x09, 0x83, 
         0x2c, 0x1a, 0x1b, 0x6e, 0x5a, 0xa0, 0x52, 0x3b, 0xd6, 0xb3, 0x29, 
         0xe3, 0x2f, 0x84, 0x53, 0xd1, 0x00, 0xed, 0x20, 0xfc, 0xb1, 0x5b, 
         0x6a, 0xcb, 0xbe, 0x39, 0x4a, 0x4c, 0x58, 0xcf, 0xd0, 0xef, 0xaa, 
         0xfb, 0x43, 0x4d, 0x33, 0x85, 0x45, 0xf9, 0x02, 0x7f, 0x50, 0x3c, 
         0x9f, 0xa8, 0x51, 0xa3, 0x40, 0x8f, 0x92, 0x9d, 0x38, 0xf5, 0xbc, 
         0xb6, 0xda, 0x21, 0x10, 0xff, 0xf3, 0xd2, 0xcd, 0x0c, 0x13, 0xec, 
         0x5f, 0x97, 0x44, 0x17, 0xc4, 0xa7, 0x7e, 0x3d, 0x64, 0x5d, 0x19, 
         0x73, 0x60, 0x81, 0x4f, 0xdc, 0x22, 0x2a, 0x90, 0x88, 0x46, 0xee, 
         0xb8, 0x14, 0xde, 0x5e, 0x0b, 0xdb, 0xe0, 0x32, 0x3a, 0x0a, 0x49, 
         0x06, 0x24, 0x5c, 0xc2, 0xd3, 0xac, 0x62, 0x91, 0x95, 0xe4, 0x79, 
         0xe7, 0xc8, 0x37, 0x6d, 0x8d, 0xd5, 0x4e, 0xa9, 0x6c, 0x56, 0xf4, 
         0xea, 0x65, 0x7a, 0xae, 0x08, 0xba, 0x78, 0x25, 0x2e, 0x1c, 0xa6, 
         0xb4, 0xc6, 0xe8, 0xdd, 0x74, 0x1f, 0x4b, 0xbd, 0x8b, 0x8a, 0x70, 
         0x3e, 0xb5, 0x66, 0x48, 0x03, 0xf6, 0x0e, 0x61, 0x35, 0x57, 0xb9, 
         0x86, 0xc1, 0x1d, 0x9e, 0xe1, 0xf8, 0x98, 0x11, 0x69, 0xd9, 0x8e, 
         0x94, 0x9b, 0x1e, 0x87, 0xe9, 0xce, 0x55, 0x28, 0xdf, 0x8c, 0xa1, 
         0x89, 0x0d, 0xbf, 0xe6, 0x42, 0x68, 0x41, 0x99, 0x2d, 0x0f, 0xb0, 
         0x54, 0xbb, 0x16 ]

rcon = [ 0x0, 0x01, 0x02, 0x04, 0x08, 0x10, 0x20, 0x40, 0x80, 0x1b, 0x36, 0x6c, 
         0xd8, 0xab, 0x4d, 0x9a, 0x2f, 0x5e, 0xbc, 0x63, 0xc6, 0x97, 0x35, 
         0x6a, 0xd4, 0xb3, 0x7d, 0xfa, 0xef, 0xc5, 0x91 ]

def blockify(data):
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
    if len(tmp_block) != 0:
        padding_char = 16 - len(tmp_block)
        while len(tmp_block) < 16:
            tmp_block.append(padding_char)
        blocks.append(tmp_block)
    return blocks

def unblockify(blocks):
    ret = []
    for b in blocks:
        for c in b:
            ret.append(c)
    
    # strip
    padding_char = ret[-1]
    good = []
    for i in range(len(ret)-1,len(ret)-padding_char-1,-1):
        if ret[i] == padding_char:
            good.append(1)
        else:
            break

    if sum(good) == padding_char:
        ret = ret[0:len(ret) - padding_char]

    return ret


def buff2ascii(buff):
    s = b""
    for c in buff:
        s += chr(c)

    return s

def ascii2buff(string):
    b = []
    for c in string:
        b.append(ord(c))

    return b

def key_expansion(key):

    def word(b0,b1,b2,b3):
        return b3 + (b2 << 8) + (b1 << 16) + (b0 << 24)

    def sub_word(w):
        b3 = w & 0xff
        b2 = (w >> 8) & 0xff
        b1 = (w >> 16) & 0xff
        b0 = (w >> 24) & 0xff

        s0 = S[b0]
        s1 = S[b1]
        s2 = S[b2]
        s3 = S[b3]

        return word(s0,s1,s2,s3)

    def rot(w):
        b3 = w & 0xff
        b2 = (w >> 8) & 0xff
        b1 = (w >> 16) & 0xff
        b0 = (w >> 24) & 0xff

        return word(b1, b2, b3, b0)
    
    # Array of 32 bit words, each grouping of 4 is a key
    keys_words = [0] * 11 * 4

    # Copy over the byte array key into the first 4 words of the keys_words
    for i in range(0, 4):
        keys_words[i] = word(key[4*i], key[4*i + 1], key[4*i + 2], key[4*i + 3])

    # the actual round expansion
    i = 4
    while i < 44:
        temp = keys_words[i-1]
        
        if ((i % 4) == 0): temp = sub_word(rot(temp)) ^ (rcon[i/4] << 24)

        keys_words[i] = keys_words[i-4] ^ temp
        i += 1

    # expand keys into an array of 11 byte arrays of length 16
    keys = []

    key_index = 0
    byte_index = 0
    tmp_key = []
    for i in range(0, 44):
        w = keys_words[i]
        b3 = w & 0xff
        b2 = (w >> 8) & 0xff
        b1 = (w >> 16) & 0xff
        b0 = (w >> 24) & 0xff

        tmp_key.append(b0)
        tmp_key.append(b1)
        tmp_key.append(b2)
        tmp_key.append(b3)

        byte_index += 4
        if byte_index == 16:
            byte_index = 0
            keys.append(tmp_key)
            tmp_key =[]

    return keys

def add_round_key(block, key):
    for i in range(0,16):
        block[i] = block[i] ^ key[i]

def base64_2hex(str):
    b = []
    for c in str:
        if ord(c) in range(ord('A'), ord('Z') + 1):
            b.append(ord(c) - ord('A'))
            continue
        if ord(c) in range(ord('a'), ord('z') + 1):
            b.append(ord(c) - ord('a') + 26)
            continue
        if ord(c) in range(ord('0'), ord('9') + 1):
            b.append(ord(c) - ord('0') + 52)
            continue
        if ord(c) == ord("+"):
            b.append(62)
            continue
        if ord(c) == ord('/'):
            b.append(63)
            continue
        if ord(c) == ord('='):
            b.append(0)
            continue
        print("ERRRORORO")
        

    if not ((len(b) % 2) == 0):
        b.insert(0,0)
        print("HERE")

    hex_buff = []
    for i in range(0,len(b)/2):
        d1 = b.pop(0)
        d2 = b.pop(0)

        v = (d1*64) + d2

        h3 = v % 16
        v = v / 16
        h2 = v % 16
        v = v / 16
        h1 = v % 16

        hex_buff.append(h1)
        hex_buff.append(h2)
        hex_buff.append(h3)

    i = 0
    out = []
    while i < len(hex_buff):
        out.append(hex_buff[i]*16 + hex_buff[i+1])
        i +=2

    return out

def poly_multi(a, b):
    result = 0
    while a and b:
        if a & 1: result ^= b
        a >>= 1; b <<= 1
    return result

def poly_mod(a, b):
    bl = b.bit_length()
    while True:
        shift = a.bit_length() - bl
        if shift < 0: return a
        a ^= b << shift

def gf_multi(a,b):
    return poly_mod(poly_multi(a, b), 0x11b)

def gf_add(a,b):
    return a ^ b


###############################################################################
# AES-128 CBC encyption Private Code
###############################################################################

def sub_bytes(block):
    for i in range(0, 16):
        block[i] = S[block[i]]

def shift_rows(block):
    # 2 row shift
    temp =  block[1]
    block[1] = block[5]
    block[5] = block[9]
    block[9] = block[13]
    block[13] = temp

    # 3 row shift
    temp = block[2]
    block[2] = block[10]
    block[10] = temp
    temp = block[6]
    block[6] = block[14]
    block[14] = temp

    # 4 row shift
    temp = block[15]
    block[15] = block[11]
    block[11] = block[7]
    block[7] = block[3]
    block[3] = temp

def mix_cols(block):
    for j in range(0,4):
        s0c = block[4*j + 0]
        s1c = block[4*j + 1]
        s2c = block[4*j + 2]
        s3c = block[4*j + 3]

        s0 = gf_add(s2c, s3c)
        s1 = gf_add(s3c, s0c)
        s2 = gf_add(s0c, s1c)
        s3 = gf_add(s1c, s2c)

        s0 = gf_add(s0, gf_multi(0x2, s0c))
        s0 = gf_add(s0, gf_multi(0x3, s1c))
        s1 = gf_add(s1, gf_multi(0x2, s1c))
        s1 = gf_add(s1, gf_multi(0x3, s2c))
        s2 = gf_add(s2, gf_multi(0x2, s2c))
        s2 = gf_add(s2, gf_multi(0x3, s3c))
        s3 = gf_add(s3, gf_multi(0x2, s3c))
        s3 = gf_add(s3, gf_multi(0x3, s0c))

        block[4*j + 0] = s0
        block[4*j + 1] = s1
        block[4*j + 2] = s2
        block[4*j + 3] = s3

def encrypt(key, block):

    keys = key_expansion(key)
    add_round_key(block, key)

    for i in range(1, 10):
        sub_bytes(block)
        shift_rows(block)
        mix_cols(block)
        add_round_key(block, keys[i])

    sub_bytes(block)
    shift_rows(block)
    add_round_key(block, keys[10])

    return block

def encrypt_cbc(key, blocks, iv):
    for block in blocks:
        if len(block) < 16:
            while len(block) != 16:
                block.append(chr(0x4))

    ct_blocks = []

    prev = iv
    for b in blocks:
        b = [prev[i] ^ b[i] for i in range(0, 16)]
        prev = encrypt(key, b)
        ct_blocks.append(prev)

    return ct_blocks

###############################################################################
# AES-128 CBC decyption Private Functions
###############################################################################

Si =[ 0x52, 0x09, 0x6a, 0xd5, 0x30, 0x36, 0xa5, 0x38, 0xbf, 0x40, 0xa3, 
      0x9e, 0x81, 0xf3, 0xd7, 0xfb, 0x7c, 0xe3, 0x39, 0x82, 0x9b, 0x2f, 
      0xff, 0x87, 0x34, 0x8e, 0x43, 0x44, 0xc4, 0xde, 0xe9, 0xcb, 0x54, 
      0x7b, 0x94, 0x32, 0xa6, 0xc2, 0x23, 0x3d, 0xee, 0x4c, 0x95, 0x0b, 
      0x42, 0xfa, 0xc3, 0x4e, 0x08, 0x2e, 0xa1, 0x66, 0x28, 0xd9, 0x24, 
      0xb2, 0x76, 0x5b, 0xa2, 0x49, 0x6d, 0x8b, 0xd1, 0x25, 0x72, 0xf8, 
      0xf6, 0x64, 0x86, 0x68, 0x98, 0x16, 0xd4, 0xa4, 0x5c, 0xcc, 0x5d, 
      0x65, 0xb6, 0x92, 0x6c, 0x70, 0x48, 0x50, 0xfd, 0xed, 0xb9, 0xda, 
      0x5e, 0x15, 0x46, 0x57, 0xa7, 0x8d, 0x9d, 0x84, 0x90, 0xd8, 0xab, 
      0x00, 0x8c, 0xbc, 0xd3, 0x0a, 0xf7, 0xe4, 0x58, 0x05, 0xb8, 0xb3, 
      0x45, 0x06, 0xd0, 0x2c, 0x1e, 0x8f, 0xca, 0x3f, 0x0f, 0x02, 0xc1, 
      0xaf, 0xbd, 0x03, 0x01, 0x13, 0x8a, 0x6b, 0x3a, 0x91, 0x11, 0x41, 
      0x4f, 0x67, 0xdc, 0xea, 0x97, 0xf2, 0xcf, 0xce, 0xf0, 0xb4, 0xe6, 
      0x73, 0x96, 0xac, 0x74, 0x22, 0xe7, 0xad, 0x35, 0x85, 0xe2, 0xf9, 
      0x37, 0xe8, 0x1c, 0x75, 0xdf, 0x6e, 0x47, 0xf1, 0x1a, 0x71, 0x1d, 
      0x29, 0xc5, 0x89, 0x6f, 0xb7, 0x62, 0x0e, 0xaa, 0x18, 0xbe, 0x1b, 
      0xfc, 0x56, 0x3e, 0x4b, 0xc6, 0xd2, 0x79, 0x20, 0x9a, 0xdb, 0xc0, 
      0xfe, 0x78, 0xcd, 0x5a, 0xf4, 0x1f, 0xdd, 0xa8, 0x33, 0x88, 0x07, 
      0xc7, 0x31, 0xb1, 0x12, 0x10, 0x59, 0x27, 0x80, 0xec, 0x5f, 0x60, 
      0x51, 0x7f, 0xa9, 0x19, 0xb5, 0x4a, 0x0d, 0x2d, 0xe5, 0x7a, 0x9f, 
      0x93, 0xc9, 0x9c, 0xef, 0xa0, 0xe0, 0x3b, 0x4d, 0xae, 0x2a, 0xf5, 
      0xb0, 0xc8, 0xeb, 0xbb, 0x3c, 0x83, 0x53, 0x99, 0x61, 0x17, 0x2b, 
      0x04, 0x7e, 0xba, 0x77, 0xd6, 0x26, 0xe1, 0x69, 0x14, 0x63, 0x55, 
      0x21, 0x0c, 0x7d ]


def inv_shift_rows(block):
    # undo shift in row 2
    temp = block[1]
    block[1] = block[13]
    block[13] = block[9]
    block[9] = block[5]
    block[5] = temp

    # undo shift in row 3
    temp = block[2]
    block[2] = block[10]
    block[10] = temp
    temp = block[6]
    block[6] = block[14]
    block[14] = temp

    # undo shift in row 4
    temp = block[3]
    block[3] = block[7]
    block[7] = block[11]
    block[11] = block[15]
    block[15] = temp

def inv_sub_bytes(block):
    for i in range(0, 16):
        block[i] = Si[block[i]]

def inv_mix_cols(block):
    for j in range(0,4):
        s0c = block[4*j + 0]
        s1c = block[4*j + 1]
        s2c = block[4*j + 2]
        s3c = block[4*j + 3]

        # First term
        s0 = gf_multi(s0c, 0x0e)
        s1 = gf_multi(s0c, 0x09)
        s2 = gf_multi(s0c, 0x0d)
        s3 = gf_multi(s0c, 0x0b)

        # Second term
        s0 = gf_add(s0, gf_multi(s1c, 0x0b))
        s1 = gf_add(s1, gf_multi(s1c, 0x0e))
        s2 = gf_add(s2, gf_multi(s1c, 0x09))
        s3 = gf_add(s3, gf_multi(s1c, 0x0d))

        # 3rd term
        s0 = gf_add(s0, gf_multi(s2c, 0x0d))
        s1 = gf_add(s1, gf_multi(s2c, 0x0b))
        s2 = gf_add(s2, gf_multi(s2c, 0x0e))
        s3 = gf_add(s3, gf_multi(s2c, 0x09))

        # last term
        s0 = gf_add(s0, gf_multi(s3c, 0x09))
        s1 = gf_add(s1, gf_multi(s3c, 0x0d))
        s2 = gf_add(s2, gf_multi(s3c, 0x0b))
        s3 = gf_add(s3, gf_multi(s3c, 0x0e))

        block[4*j + 0] = s0
        block[4*j + 1] = s1
        block[4*j + 2] = s2
        block[4*j + 3] = s3

def decrypt(key, block):
    keys = key_expansion(key)
    add_round_key(block, keys[10])

    i = 9
    while(i != 0):
        inv_shift_rows(block)
        inv_sub_bytes(block)
        add_round_key(block, keys[i])
        inv_mix_cols(block)
        i = i - 1

    inv_shift_rows(block)
    inv_sub_bytes(block)
    add_round_key(block, keys[0])

    return block

def decrypt_cbc(key, blocks, iv):
    pt_blocks = []
    i = 0
    prev = [iv[j] for j in range(0,16)]
    for i in range(0, len(blocks)):
        # save off ct before we unscamble it
        save = [blocks[i][j] for j in range(0,16)]

        # decrypts block in place, this modifies blocks[i]
        pt = decrypt(key, blocks[i])

        # xor out our pt
        pt_blocks.append([(pt[j] ^ prev[j]) for j in range(0,16)])

        # copy the saved off block to previous
        prev = [save[j] for j in range(0,16)]
    return pt_blocks

###############################################################################
# AES-128 Counter Mode Private Functions
###############################################################################

def build_nonce_block(val):
    ret = []
    # assume val < 2^64

    for i in range(0,8):
        ret.append(0)

    for i in range(0,8):
        ret.append(val % 256)
        val = val / 256

    return ret

def build_key_stream(key, nonce, size_data):
    # produce the key stream
    num_key_blocks = size_data / 16
    if not size_data % 16 == 0:
        num_key_blocks += 1

    blocks = []
    for i in range(0, num_key_blocks):
        val = i + nonce
        blocks.append(build_nonce_block(val))

    ct_stream = []
    for b in blocks:
        ct_stream += encrypt(key, b)

    return ct_stream

def encrypt_ctr(key, nonce, data):
    ct_stream = build_key_stream(key, nonce, len(data))
    ct_data = []
    for i in range(0, len(data)):
        ct_data.append(data[i] ^ ct_stream[i])
    return ct_data

def decrypt_ctr(key, nonce, ct_data):
    return encrypt_ctr(key, nonce, ct_data)