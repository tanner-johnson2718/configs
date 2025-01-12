from aes_cbc import *

in_strs = ["SSBoYXZlIG1ldCB0aGVtIGF0IGNsb3NlIG9mIGRheQ==",
"Q29taW5nIHdpdGggdml2aWQgZmFjZXM=",
"RnJvbSBjb3VudGVyIG9yIGRlc2sgYW1vbmcgZ3JleQ==",
"RWlnaHRlZW50aC1jZW50dXJ5IGhvdXNlcy4=",
"SSBoYXZlIHBhc3NlZCB3aXRoIGEgbm9kIG9mIHRoZSBoZWFk",
"T3IgcG9saXRlIG1lYW5pbmdsZXNzIHdvcmRzLA==",
"T3IgaGF2ZSBsaW5nZXJlZCBhd2hpbGUgYW5kIHNhaWQ=",
"UG9saXRlIG1lYW5pbmdsZXNzIHdvcmRzLA==",
"QW5kIHRob3VnaHQgYmVmb3JlIEkgaGFkIGRvbmU=",
"T2YgYSBtb2NraW5nIHRhbGUgb3IgYSBnaWJl",
"VG8gcGxlYXNlIGEgY29tcGFuaW9u",
"QXJvdW5kIHRoZSBmaXJlIGF0IHRoZSBjbHViLA==",
"QmVpbmcgY2VydGFpbiB0aGF0IHRoZXkgYW5kIEk=",
"QnV0IGxpdmVkIHdoZXJlIG1vdGxleSBpcyB3b3JuOg==",
"QWxsIGNoYW5nZWQsIGNoYW5nZWQgdXR0ZXJseTo=",
"QSB0ZXJyaWJsZSBiZWF1dHkgaXMgYm9ybi4=",
"VGhhdCB3b21hbidzIGRheXMgd2VyZSBzcGVudA==",
"SW4gaWdub3JhbnQgZ29vZCB3aWxsLA==",
"SGVyIG5pZ2h0cyBpbiBhcmd1bWVudA==",
"VW50aWwgaGVyIHZvaWNlIGdyZXcgc2hyaWxsLg==",
"V2hhdCB2b2ljZSBtb3JlIHN3ZWV0IHRoYW4gaGVycw==",
"V2hlbiB5b3VuZyBhbmQgYmVhdXRpZnVsLA==",
"U2hlIHJvZGUgdG8gaGFycmllcnM/",
"VGhpcyBtYW4gaGFkIGtlcHQgYSBzY2hvb2w=",
"QW5kIHJvZGUgb3VyIHdpbmdlZCBob3JzZS4=",
"VGhpcyBvdGhlciBoaXMgaGVscGVyIGFuZCBmcmllbmQ=",
"V2FzIGNvbWluZyBpbnRvIGhpcyBmb3JjZTs=",
"SGUgbWlnaHQgaGF2ZSB3b24gZmFtZSBpbiB0aGUgZW5kLA==",
"U28gc2Vuc2l0aXZlIGhpcyBuYXR1cmUgc2VlbWVkLA==",
"U28gZGFyaW5nIGFuZCBzd2VldCBoaXMgdGhvdWdodC4=",
"VGhpcyBvdGhlciBtYW4gSSBoYWQgZHJlYW1lZA==",
"QSBkcnVua2VuLCB2YWluLWdsb3Jpb3VzIGxvdXQu",
"SGUgaGFkIGRvbmUgbW9zdCBiaXR0ZXIgd3Jvbmc=",
"VG8gc29tZSB3aG8gYXJlIG5lYXIgbXkgaGVhcnQs",
"WWV0IEkgbnVtYmVyIGhpbSBpbiB0aGUgc29uZzs=",
"SGUsIHRvbywgaGFzIHJlc2lnbmVkIGhpcyBwYXJ0",
"SW4gdGhlIGNhc3VhbCBjb21lZHk7",
"SGUsIHRvbywgaGFzIGJlZW4gY2hhbmdlZCBpbiBoaXMgdHVybiw=",
"VHJhbnNmb3JtZWQgdXR0ZXJseTo=",
"QSB0ZXJyaWJsZSBiZWF1dHkgaXMgYm9ybi4="]

in_data = map(base64_2hex, in_strs)

key = [i for i in range(0,16)]
def temp_func(data):   
    return encrypt_ctr(key, 0, data)


# Let's assume all we have is this series of ct data. We know it used a fixed 
# nonce of unkown value and a fixed key of unknown value to encrypt each datum
# succesivly. Goal is to reproduce the key stream and thus the pt. We also know
# the data is english plain text.
ct_datas = map(temp_func, in_data)

def is_alpha(byte):
    if byte == ord(' '):
        return 1
    if byte >= ord('a') and byte <= ord('z'):
        return 1
    if byte >= ord('A') and byte <= ord('Z'):
        return 0
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

# lets just look at the first byte of each datum, iterate all possible 256
# first bytes of the key stream and the one that maps to alpha numeric chars
# is probablty the first byte
key_stream = [198, 161, 59, 55, 135, 143, 91, 130, 111, 79, 129, 98, 161, 200, 216, 121, 95, 44, 128, 211, 82, 211, 232, 252, 180, 174, 164, 56, 24, 141, 119, 200, 221, 30, 34, 156]

target_byte = len(key_stream)
score_board = []
for byte in range(0,256):
    score = 0
    for datum in ct_datas:
        if target_byte < len(datum):   
            score += is_alpha(byte ^ datum[target_byte])
    score_board.append(score)
print(score_board)
print(score_board.index(max(score_board)))
print(max(score_board))



for datum in ct_datas:
    string = ""
    for i in range(0,min(len(key_stream), len(datum))):
        string += chr(datum[i] ^ key_stream[i])
    print(string)