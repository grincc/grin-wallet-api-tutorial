#!/usr/bin/env bash

iv=$(openssl rand -hex 12)
dest_acct_name=$1
slate_file=$2
slate=$(cat $slate_file)
payload=$(echo "{\"id\":\"$iv\",\"method\":\"receive_tx\",\"params\":[$slate,\"$dest_acct_name\",null]}")
echo $payload > /tmp/$iv.slate.json
result=$(curl -s -X POST http://127.0.0.1:3420/v2/foreign -H 'Content-Type: application/json' -d @/tmp/$iv.slate.json | jq .result)
rm -f /tmp/$iv.slate.json
if $(echo $result | jq 'has("Err")')
then
    echo $result | jq .Err
    exit 1
else
    echo $result | jq .Ok
fi
exit 0
