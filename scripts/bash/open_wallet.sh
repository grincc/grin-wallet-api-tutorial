#!/usr/bin/env bash

iv=$(openssl rand -hex 12)
echo -n "Password of the wallet: "; read -s password
payload=$(echo "{\"id\":\"$iv\",\"method\":\"open_wallet\",\"params\":{\"name\":null,\"password\":\"$password\"}}")
payload=$(.venv/bin/python ./scripts/python/encrypt.py "$1" "$iv" "$payload")
unset password
read body_enc nonce < <(echo $(curl -s --user grin:$(cat ~/.grin/main/.owner_api_secret) -d '{"jsonrpc":"2.0", "id":"'"$iv"'","method":"encrypted_request_v3","params":{"nonce":"'"$iv"'","body_enc":"'"$payload"'"}}' -o - http://127.0.0.1:3420/v3/owner | jq -r '.result.Ok.body_enc, .result.Ok.nonce'))
unset payload
result=$(.venv/bin/python ./scripts/python/decrypt.py $1 $nonce $body_enc)
echo $result
if $(echo $result | jq 'has("error")')
then
    echo $result | jq .error.message
else
    echo "Wallet opened."
    token = $(echo $result | jq .result.Ok)
    echo -n "Where you want the Token [$token]?: "; read token_path
    [ -z "$token_path" ] && echo $token >> $token_path
fi
