#!/usr/bin/env bash

iv=$(openssl rand -hex 12)
echo -n "Password for the wallet: "; read -s password
echo ""
echo -n "Confirm Password: "; read -s password_confirmation
[[ "$password" != "$password_confirmation" ]] && echo "Passwords are not equal" && exit 1
payload=$(echo "{\"id\":\"$iv\",\"method\":\"create_wallet\",\"params\":{\"name\":null,\"mnemonic\":null,\"mnemonic_length\":32,\"password\":\"$password\"}}")
payload=$(.venv/bin/python ./scripts/python/encrypt.py "$1" "$iv" "$payload")
unset password
unset password_confirmation
read body_enc nonce < <(echo $(curl -s --user grin:$(cat ~/.grin/main/.owner_api_secret) -d '{"jsonrpc":"2.0", "id":"'"$iv"'","method":"encrypted_request_v3","params":{"nonce":"'"$iv"'","body_enc":"'"$payload"'"}}' -o - http://127.0.0.1:3420/v3/owner | jq -r '.result.Ok.body_enc, .result.Ok.nonce'))
unset payload
result=$(.venv/bin/python ./scripts/python/decrypt.py $1 $nonce $body_enc)
echo ""
if $(echo $result | jq 'has("error")')
then
    echo $result | jq .error.message
    exit 1
else
    echo "Wallet created"
fi
exit 0
