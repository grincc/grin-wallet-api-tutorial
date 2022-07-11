#!/usr/bin/env python3

import base64
import sys

from Crypto.Cipher import AES


def encrypt(key, text, nonce_hex):
    aes_cipher = AES.new(bytes.fromhex(key), AES.MODE_GCM, nonce=bytes.fromhex(nonce_hex))
    text = str.encode(text)
    ciphertext, auth_tag = aes_cipher.encrypt_and_digest(text)
    return base64.b64encode(ciphertext + auth_tag).decode()

shared_secret_key = sys.argv[1]
nonce = sys.argv[2]
payload = sys.argv[3]

print(encrypt(key=shared_secret_key, text=payload, nonce_hex=nonce), end="")
