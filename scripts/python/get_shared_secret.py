#!/usr/bin/env python3

import hashlib
import os
import subprocess
import sys
from pathlib import Path

import requests
from ecdsa import ECDH, SECP256k1, SigningKey, VerifyingKey

# default username is 'grin'
api_user = "grin"
# password for owner api, location ~/.grin/main/.owner_api_secret (for mainnet)
owner_api_secret = Path(
    os.path.join(str(Path.home()), ".grin/main/.owner_api_secret")
).read_text()
wallet_api_address = "127.0.0.1:3420"
api_url = f"http://{wallet_api_address}/v3/owner"

# Private Key Hex String
private_key_pem_file = "private_key.pem"
if len(sys.argv) > 0:
    private_key_pem_file = sys.argv[1]
private_key_hex = (
    subprocess.check_output(
        f"openssl ec -in {private_key_pem_file} -outform DER 2> /dev/null | xxd -p -c0",
        shell=True,
    )
    .decode("utf-8")
    .rstrip()
)

# Create Private Key object from Private Key Hex String
sk = SigningKey.from_der(bytearray.fromhex(private_key_hex), hashfunc=hashlib.sha256)
# Get Public Key
public_key = sk.get_verifying_key().to_string("compressed").hex()

# Now we need a public key from the server to compute the shared secret
payload = {
    "jsonrpc": "2.0",
    "id": 1,
    "method": "init_secure_api",
    "params": {"ecdh_pubkey": public_key},
}
response = requests.post(
    api_url, json=payload, auth=(api_user, owner_api_secret)
).json()

remote_pubic_key = response["result"]["Ok"]  # the returned public key is a hex

# now we pass our private key and their public key
shared_secret = (
    ECDH(
        curve=SECP256k1,
        private_key=sk,
        public_key=VerifyingKey.from_string(
            bytes.fromhex(remote_pubic_key), curve=SECP256k1, hashfunc=hashlib.sha256
        ),
    )
    .generate_sharedsecret_bytes()
    .hex()
)

print(f"{shared_secret}", end="")
