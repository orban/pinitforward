#!/bin/bash

# modified from: https://github.com/ipfs/ipfs-webui/blob/main/cors-config.sh

ALLOW_ORIGINS='"https://pinitforward.xyz", "http://localhost:3000", "https://webui.ipfs.io", "https://dev.webui.ipfs.io"'

# stop executing if anything fails
set -e

ipfs config --json API.HTTPHeaders.Access-Control-Allow-Origin "[$ALLOW_ORIGINS]"
ipfs config --json API.HTTPHeaders.Access-Control-Allow-Methods '["PUT", "POST"]'

echo "IPFS API CORS headers configured for $ALLOW_ORIGINS"
echo "Please restart your IPFS daemon"