#!/usr/bin/env bash

iv=$(openssl rand -hex 12)
account=$3
amount=$(bc <<< "$4/1")
recipient="null"
[ -n "$5" ] && recipient="\"$5\""
payload=$(echo "{\"id\":\"$iv\",\"method\":\"init_send_tx\",\"params\":{\"token\":\"$2\",\"args\":{\"src_acct_name\":\"$account\",\"amount\":\"$amount\",\"minimum_confirmations\":10,\"max_outputs\":500,\"num_change_outputs\":1,\"selection_strategy_is_use_all\":true,\"target_slate_version\":null,\"payment_proof_recipient_address\":$recipient,\"ttl_blocks\":null,\"send_args\":null}}}")
payload=$(.venv/bin/python ./scripts/python/encrypt.py "$1" "$iv" "$payload")
read body_enc nonce < <(echo $(curl -s --user grin:$(cat ~/.grin/main/.owner_api_secret) -d '{"jsonrpc":"2.0", "id":"'"$iv"'","method":"encrypted_request_v3","params":{"nonce":"'"$iv"'","body_enc":"'"$payload"'"}}' -o - http://127.0.0.1:3420/v3/owner | jq -r '.result.Ok.body_enc, .result.Ok.nonce'))
unset payload
result=$(.venv/bin/python ./scripts/python/decrypt.py $1 $nonce $body_enc)
if $(echo $result | jq 'has("error")')
then
    echo $result | jq .error.message
    exit 1
else
    echo $result | jq -r .result.Ok
fi
exit 0
