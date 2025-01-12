from aes_cbc import *

lines = open("data_c20.txt", "r").read().splitlines()

pt_data = []
for line in lines:
    pt_data.append(base64_2hex(line))
pt_readable = map(buff2ascii, pt_data)

min_len = min(map(len, pt_data))
for i in range(0, len(pt_data)):
    pt_data[i] = pt_data[i][0:min_len]

key = [i for i in range(0,16)]
def temp(data):
    return encrypt_ctr(key, 0, data)
ct_data = map(temp, pt_data)

def is_alpha(byte):
    if byte == ord(' '):
        return 1
    if byte >= ord('a') and byte <= ord('z'):
        return 1
    if byte >= ord('A') and byte <= ord('Z'):
        return 1
    if byte == ord('\''):
        return 0
    if byte == ord('.'):
        return 1
    if byte >= ord('0') and byte <= ord('9'):
        return 0
    if byte == ord(","):
        return 1
    if byte == ord("-"):
        return 1
    if byte == ord("?"):
        return 1
    if byte == ord("\n"):
        return 0
    if byte == ord(':'):
        return 1
    return 0

key_stream = []
for target_byte in range(0, len(ct_data[0])):
    score_board = []
    for byte in range(0,256):
        score = 0
        for datum in ct_data: 
            score += is_alpha(byte ^ datum[target_byte])
        score_board.append(score)
    key_stream.append(score_board.index(max(score_board)))

for datum in ct_data:
    string = ""
    for i in range(0,min(len(key_stream), len(datum))):
        string += chr(datum[i] ^ key_stream[i])
    print(string)