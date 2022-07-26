#!/usr/bin/env bash

iv=$(openssl rand -hex 12)
slate=$(cat $2)
slate=$(echo "${slate//[$'\t\r\n']}" | sed 's/ //g')
result=`ALL_PROXY=socks5h://localhost:9050 http --timeout=120 POST $(php scripts/php/grin1.php -a $1) jsonrpc="2.0" id=$iv method="receive_tx" params[]:=$slate params[]=null params[]=null`
if $(echo $result | jq 'has("error")')
then
    echo $result | jq .error.message
    exit 1
else
    echo $result | jq .result.Ok
fi
exit 0
