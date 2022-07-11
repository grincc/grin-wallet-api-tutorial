#!/usr/bin/env bash

iv=$(openssl rand -hex 12)
echo -n "Password of the wallet: "; read -s password
payload=$(echo "{\"id\":\"$iv\",\"method\":\"open_wallet\",\"params\":{\"name\":null,\"password\":\"$password\"}}")
payload=$(.venv/bin/python ./scripts/python/encrypt.py "$1" "$iv" "$payload")
unset password
read body_enc nonce < <(echo $(curl -s --user grin:$(cat ~/.grin/main/.owner_api_secret) -d '{"jsonrpc":"2.0", "id":"'"$iv"'","method":"encrypted_request_v3","params":{"nonce":"'"$iv"'","body_enc":"'"$payload"'"}}' -o - http://127.0.0.1:3420/v3/owner | jq -r '.result.Ok.body_enc, .result.Ok.nonce'))
unset payload
result=$(.venv/bin/python ./scripts/python/decrypt.py $1 $nonce $body_enc)
echo ""
if $(echo $result | jq 'has("error")')
then
    echo $result | jq .error.message
    exit 1
else
    token=$(echo $result | jq -r .result.Ok)
    echo "Wallet opened [token=$token]"
    [ -n "$2" ] && echo $token > $2
fi
exit 0
