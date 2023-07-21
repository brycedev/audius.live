#!/bin/sh

echo "Pulling code..."
cd ~/audius.live
git submodule update --remote
git reset --hard
git pull --recurse-submodules origin main
echo "Updating mix deps..."
/usr/local/bin/mix deps.get --only prod
echo "Compiling..."
MIX_ENV=prod /usr/local/bin/mix compile
echo "Setting up assets..."
npm install --prefix assets
MIX_ENV=prod /usr/local/bin/mix assets.deploy
MIX_ENV=prod /usr/local/bin/mix phx.digest
echo "Releasing..."
source .env && MIX_ENV=prod /usr/local/bin/mix release --overwrite
MIX_ENV=prod /usr/local/bin/mix ecto.migrate
echo "Starting server..."
source .env && _build/prod/rel/audius_live/bin/audius_live daemon
echo "All done."