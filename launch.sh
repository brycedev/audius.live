#!/bin/sh

echo "Pulling code..."
cd ~/audius.live
git submodule update --remote
git reset --hard
git pull --recurse-submodules origin main
echo "Updating mix deps..."
mix deps.get --only prod
echo "Compiling..."
MIX_ENV=prod mix compile
echo "Setting up assets..."
npm install --prefix assets
MIX_ENV=prod mix assets.deploy
MIX_ENV=prod mix phx.digest
echo "Releasing..."
source .env && MIX_ENV=prod mix release --overwrite
MIX_ENV=prod mix ecto.migrate
echo "Starting server..."
source .env && _build/prod/rel/audius_live/bin/audius_live daemon
echo "All done."