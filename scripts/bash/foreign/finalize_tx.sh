#!/usr/bin/env bash

iv=$(openssl rand -hex 12)
slate=$(cat $1)
slate=$(echo "${slate//[$'\t\r\n']}" | sed 's/ //g')
result=`.venv/bin/http POST "https://127.0.0.1:3420/v2/foreign" jsonrpc="2.0" id=$iv method="finalize_tx" params[]:=$slate`
if $(echo $result | jq 'has("error")')
then
    echo $result | jq .error.message
    exit 1
else
    echo $result | jq .result.Ok
fi
exit 0
