#!/usr/bin/env sh

# abort on errors
set -e

# build
npm run build

# if you are deploying to a custom domain
echo 'www.pinitforward.xyz' > docs/CNAME

git add docs/
git commit -m 'deploy'
git push origin

