from aes_cbc import *

key_str = "YELLOW SUBMARINE"
key_data = ascii2buff(key_str)

ct_str = "L77na/nrFsKvynd6HzOoG7GHTLXsTVu9qvY/2syLXzhPweyyMTJULu/6/kXX0KSvoOLSFQAA"
ct_data = base64_2hex(ct_str)

pt_data = decrypt_ctr(key_data, 0, ct_data)
print(buff2ascii(pt_data))


print(buff2ascii(decrypt_ctr(key_data, 0, encrypt_ctr(key_data, 0, ascii2buff("Sup my homies")))))