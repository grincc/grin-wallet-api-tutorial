#!/usr/bin/env bash

iv=$(openssl rand -hex 12)
slate=$(cat $2)
result=`ALL_PROXY=socks5h://localhost:9050 http -v POST $(php scripts/php/grin1.php -a $1) jsonrpc="2.0" id=$iv method="receive_tx" params[]:=$slate params[]=null params[]=null`
if $(echo $result | jq 'has("error")')
then
    echo $result | jq .error.message
    exit 1
else
    echo $result | jq .result.Ok.supported_slate_versions[0]
fi
exit 0
