#!/usr/bin/env bash

iv=$(openssl rand -hex 12)
echo -n "Node IP: "; read api
echo -n "Absolute path of Wallet: "; read path
payload=$(echo "{\"id\":\"$iv\",\"method\":\"create_config\",\"params\":{\"chain_type\":\"Mainnet\",\"logging_config\":null,\"tor_config\":null,\"wallet_config\":{\"api_secret_path\":null,\"chain_type\":\"Mainnet\",\"node_api_secret_path\":null,\"data_file_dir\":\"$path\",\"no_commit_cache\":null,\"tls_certificate_file\":null,\"tls_certificate_key\":null,\"dark_background_color_scheme\":null,\"keybase_notify_ttl\":null,\"api_listen_interface\":\"127.0.0.1\",\"api_listen_port\": 3415,\"owner_api_listen_port\":3420,\"check_node_api_http_addr\":\"http://$api:13413\",\"owner_api_include_foreign\": false}}}")
payload=$(.venv/bin/python ./scripts/python/encrypt.py "$1" "$iv" "$payload")
unset api
read body_enc nonce < <(echo $(curl -s --user grin:$(cat ~/.grin/test/.owner_api_secret) -d '{"jsonrpc":"2.0", "id":"'"$iv"'","method":"encrypted_request_v3","params":{"nonce":"'"$iv"'","body_enc":"'"$payload"'"}}' -o - http://127.0.0.1:13420/v3/owner | jq -r '.result.Ok.body_enc, .result.Ok.nonce'))
unset payload
if [ "$body_enc" = "null" ] || [ "$body_enc" = "" ] || [ -z "$body_enc" ]; then
    echo "Empty response from API. Exiting..."
    exit 1
fi
result=$(.venv/bin/python ./scripts/python/decrypt.py $1 $nonce $body_enc)
if $(echo $result | jq 'has("error")')
then
    echo $result | jq .error.message
    exit 1
else
    echo "Config created"
fi
exit 0
