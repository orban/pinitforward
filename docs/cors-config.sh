#!/bin/bash

# modified from: https://github.com/ipfs/ipfs-webui/blob/main/cors-config.sh

ALLOW_ORIGINS='"https://pinitforward.xyz", "https://www.pinitforward.xyz", "webui://-", "http://localhost:3000", "http://127.0.0.1:5001", "https://webui.ipfs.io"'

# stop executing if anything fails
set -e

ipfs config --json API.HTTPHeaders.Access-Control-Allow-Origin "[$ALLOW_ORIGINS]"
ipfs config --json API.HTTPHeaders.Access-Control-Allow-Methods '["PUT", "POST"]'

echo "IPFS API CORS headers configured for $ALLOW_ORIGINS"
echo "Please restart your IPFS daemon"