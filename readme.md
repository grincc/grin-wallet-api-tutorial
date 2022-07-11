# How to communicate securely with the grin-wallet API

In this document I will define the basis of proper communication with the grin-wallet API, which is the use of secure JSON-RPC calls. A shared key must first be calculated before calling any other JSON-RPC method. All subsequent requests and responses will be then encrypted and decrypted with the following parameters:

- AES-256 in GCM mode with 128-bit tags and 96 bit nonces
- 12 byte nonce which must be included in each request/response to use on the decrypting side
- Empty vector for additional data
- Suffix length = AES-256 GCM mode tag length = 16 bytes

JSON-RPC requests should be encrypted using these parameters, encoded into base64 and included with the one-time nonce.

Before starting make sure you have installed the next tools: ``` openssl, wget, curl, sha256sum, tar, tor, wget, python3, libncursesw5 ```

This document assumes that you are **running Linux**. You will need to create a `$CHAIN` variable in your environment, if you intent to use `Testnet` the value of `$CHAIN` must be `test`, but in case that you are using `Mainnet` the value must be `main`:

For Mainnet:

```bash
export CHAIN="main"
```

For Testnet:

```bash
export CHAIN="test"
```

## Installing the latest version of grin wallet and node

Go to grin.mw/download and download the tgz files of grin and grin-wallet by clicking on their name titles. Or alternatively, type in the terminal:

```bash
wget https://github.com/mimblewimble/grin/releases/download/v5.1.2/grin-v5.1.2-linux-amd64.tar.gz
wget https://github.com/mimblewimble/grin-wallet/releases/download/v5.1.0/grin-wallet-v5.1.0-linux-amd64.tar.gz

```

To verify the release, calculate the sha256sum of the binaries and compare the result against their respective SHA256 HASH on the website (or in releases).

```bash
sha256sum grin-v5.1.0-linux-amd64.tar.gz
sha256sum grin-wallet-v5.1.0-linux-amd64.tar.gz
```

Next, navigate to the directory where the files were downloaded and extract the binaries:

```bash
sudo tar -C /usr/local/bin -xzf grin-v5.1.2-linux-amd64.tar.gz --strip-components=1
sudo tar -C /usr/local/bin -xzf grin-wallet-v5.1.0-linux-amd64.tar.gz --strip-components=1
```

NOTE: In every command replace `v5.1.2` and `v5.1.0` with the **appropriate stable version** for each binary. For the node go [here](https://github.com/mimblewimble/grin/releases) and for the wallet go [here](https://github.com/mimblewimble/grin-wallet/releases).

## Starting node and wallet APIs

Now, open 3 new tabs from your terminal. In the first tab, run the node with the next command for Mainnet:

```bash
grin
```

For Testnet:

```bash
grin --testnet
```

In the second tab, you need need to start the wallet api, for Mainnet:

```bash
grin-wallet owner_api --run_foreign
```

For Testnet:

```bash
grin-wallet --testnet owner_api --run_foreign
```

The Owner API is intended to expose methods that are to be used by the wallet owner only and the "Foreign" API contains methods that other wallets will use to interact with the owner's wallet.

Use the third tabs to go through the next steps.

## Generating a private key

In order to obtain the `shared key` we frist need to have a private key. Run the next command to generate and encrypt your private key using a strong pass phrase:

```bash
openssl ecparam -genkey -name secp256k1 -param_enc explicit | openssl ec -aes256 -out private_key.pem
```

You have to get an output like the next:

```text
read EC key
writing EC key
Enter PEM pass phrase:
Verifying - Enter PEM pass phrase:
```

Make sure to keep safe the key file `private_key.pem` and the pass phrase used.

To confirm that the key was succesfully created, execute the next command:

```bash
$ ls -lh private_key.pem
-rw-r--r--  1 david  staff   529B Jul 10 15:53 private_key.pem
```

Also you can read the private key like this:

```bash
openssl pkey -in private_key.pem -inform pem -noout -text
```

You will see something like this:

```text
Enter pass phrase for private_key.pem:
Private-Key: (256 bit)
priv:
    08:f5:49:3d:3e:08:7f:57:65:dd:05:93:e0:b0:56:
    9d:4e:da:ff:b8:40:7e:70:ee:85:33:b9:08:fe:b6:
    b5:ae
pub:
    04:f6:55:f6:5d:01:2d:2e:ca:4a:35:1c:6f:89:ae:
    73:88:9d:28:a4:88:65:bf:6e:58:6d:1a:3c:1f:37:
    8f:68:09:8d:37:1b:96:a5:61:17:b0:6f:11:b9:fa:
    02:f8:65:16:77:30:7a:18:09:f8:28:1f:22:b8:0c:
    52:e6:de:07:e6
Field Type: prime-field
Prime:
    00:ff:ff:ff:ff:ff:ff:ff:ff:ff:ff:ff:ff:ff:ff:
    ff:ff:ff:ff:ff:ff:ff:ff:ff:ff:ff:ff:ff:fe:ff:
    ff:fc:2f
A:    0
B:    7 (0x7)
Generator (uncompressed):
    04:79:be:66:7e:f9:dc:bb:ac:55:a0:62:95:ce:87:
    0b:07:02:9b:fc:db:2d:ce:28:d9:59:f2:81:5b:16:
    f8:17:98:48:3a:da:77:26:a3:c4:65:5d:a4:fb:fc:
    0e:11:08:a8:fd:17:b4:48:a6:85:54:19:9c:47:d0:
    8f:fb:10:d4:b8
Order:
    00:ff:ff:ff:ff:ff:ff:ff:ff:ff:ff:ff:ff:ff:ff:
    ff:fe:ba:ae:dc:e6:af:48:a0:3b:bf:d2:5e:8c:d0:
    36:41:41
Cofactor:  1 (0x1)
```

## Preparing a Python virtual enviroment

A virtual environment is a Python environment such that the Python interpreter, libraries and scripts installed into it are isolated from those installed in other virtual environments, and (by default) any libraries installed in a "system" Python, i.e., one which is installed as part of your operating system. In order to create a virtual environment run the next command:

```bash
python3 -m virtualenv .venv
```

After that, proceed to activate the recently created environment:

```bash
source .venv/bin/activate
```

After activating the virtual environment we need to be install all dependencies. In order to do so, execute the next command:

```bash
pip install requests pycryptodome ecdsa
```

NOTE: All the steps below must be followed inside the virtual environment.

## Running Grin Node as a Service

Before continuing let's create a service to manage the node.

Go to the tab where the node is running and press `Q`. Now open the node configuration like this:

```bash
nano .grin/$CHAIN/grin-server.toml
```

Find the `run_tui` parameter and change it to `false`.

```ini
run_tui = false
```

Also if you want to run your node in a separate server from the wallet which is recommended, please change `api_http_addr` to run on your server IP, example:

```ini
api_http_addr = "192.168.0.10:3413"
```

NOTE: Make sure you are using your own IP.

Create a file here: `/etc/.grinconf` with this content for Mainnet:

```bash
CHAIN_TYPE=""
```

Or this for Testnet:

```bash
CHAIN_TYPE="--testnet"
```

This will tell the node which is the desired chain. Now create a file on `/etc/systemd/system/grin.node.service` and paste the next content inside:

```ini
[Unit]
Description=Grin Node Service
After=network.target

[Service]
Type=simple
EnvironmentFile=/etc/.grinconf
ExecStart=/usr/local/bin/grin $CHAIN_TYPE
Restart=always
User=root
Group=root

[Install]
WantedBy=multi-user.target
```

NOTE: Make sure `ExecStart` contains the correct path.

One can now enable and start the node service:

```bash
systemctl enable grin.node.service && systemctl start grin.node.service
```

We can check the status like this:

```bash
systemctl status grin.node.service
```

You see will now the status:

```text
grin.node.service - Grin Node Service
   Loaded: loaded (/etc/systemd/system/grin.node.service; enabled; vendor preset: enabled)
   Active: active (running) since Sun 2022-07-10 12:50:14 CEST; 3h 49min ago
 Main PID: 26784 (grin)
    Tasks: 89 (limit: 2359)
   Memory: 600.8M
   CGroup: /system.slice/grin.node.service
           └─26784 /usr/local/bin/grin
```

## Obtaining the Shared Key

We need to obtain a shared key to be able to communicate securely with the API, for this we will use the [private key generated previously](#generating-a-private-key). Run the next command and pass the path of the PEM file of the private key:

```bash
python scripts/python/$CHAIN/get_shared_secret.py private_key.pem 2> /dev/null > ~/.grin/$CHAIN/.shared_secret
```

The secret key will be written on the next path `~/.grin/$CHAIN/.shared_secret` you can confirm that everything is OK by displaying the content of the file:

```bash
ls -lh ~/.grin/$CHAIN/.shared_secret
```

It should be a 64 bytes file:

```text
-rw-r--r--  1 david  staff    64B Jul 10 16:02 /Users/david/.grin/$CHAIN/.shared_secret
```

```bash
cat ~/.grin/$CHAIN/.shared_secret
```

You should see something like the next:

```bash
3a82acc078e6db6bf08dc1b17c65f001e64a237f1a1e162d91b467221d907575
```

This is the shared key and will be used then to encrypt and decrypt the parameters and the responses with the API. This `shared_secret`key will be use to encrypt and decrypt the API calls and response. This must be done everytime you start the owner API.

## Creating a Wallet

Now, we are ready to create a wallet. Remember that the wallet information will be stored in the directory set in the previous step by calling the `set_top_level_directory` method or in `~/.grin/$CHAIN/wallet_data` by default if `set_top_level_directory` has not been called. In order to create a wallet we will need to call: [`create_wallet`](https://docs.rs/grin_wallet_api/4.0.0/grin_wallet_api/trait.OwnerRpc.html#tymethod.create_wallet), which parameters are the next:

```json
{
    "name": null,
    "mnemonic": null,
    "mnemonic_length": 32,
    "password": "my_secret_password"
}
```

Parameters: `name` and `mnemonic` are optional, `mnemonic_length` specify the length of the seed phrase and `password` is the password of the wallet. This password is also used to encrypt the wallet data on disk.

```bash
./scripts/bash/$CHAIN/create_wallet.sh $(cat ~/.grin/$CHAIN/.shared_secret)
```

To confirm that the wallet was created please go to the path previously set and list the file:

```bash
ls -lh
```

You should see something like this:

```text
drwxr-xr-x  5 david  staff   160B Jul 10 16:20 wallet_data
```

## Opening a Wallet

Now that the wallet is created we can open it. This means that we can interact with the wallet.

```bash
./scripts/bash/$CHAIN/open_wallet.sh $(cat ~/.grin/$CHAIN/.shared_secret)
```

## Optional

### Setting the top level directory

You can specify the directory where the wallet information will be stored. If you are not using an [encrypted volume](https://guardianproject.info/archive/luks/) at least, try to use an [encrypted filesystem in user-space](https://github.com/vgough/encfs). To do this, we need to call the `set_top_level_directory` endpoint.

```bash
./scripts/bash/$CHAIN/set_top_level_directory.sh $(cat ~/.grin/$CHAIN/.shared_secret)
```
