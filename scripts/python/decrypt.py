#!/usr/bin/env python3

import base64
import sys

from Crypto.Cipher import AES


def decrypt(key, data, nonce_hex):
    data = base64.b64decode(data)
    ciphertext = data[:-16]
    aesCipher = AES.new(bytes.fromhex(key), AES.MODE_GCM, nonce=bytes.fromhex(nonce_hex))
    plaintext = aesCipher.decrypt(ciphertext)
    return plaintext.decode()

shared_secret_key = sys.argv[1]
nonce = sys.argv[2]
payload = sys.argv[3]

print(decrypt(key=shared_secret_key, data=payload, nonce_hex=nonce), end="")
