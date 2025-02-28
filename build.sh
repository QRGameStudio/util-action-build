set -xEeuo pipefail

cd "$(dirname $(realpath "$0"))/.."

jq --version &> /dev/null || apt install -y jq

eval `ssh-agent -s`
echo "$REPO_DEPLOY_SSH_KEY" | tr -d '\r' | ssh-add -

git clone https://github.com/QRGameStudio/util-games-builder.git
cd util-games-builder
npm i
cd ..
if [ ! -e game.html ];
    then tsc --outFile game.js -lib dom,es6 src/main.ts
fi
if [ -d public ];
    then cp -r public/* .
fi
node util-games-builder/build-game.js game.html --too-large-ok
rm -r dist/aux
GAME_ID="$(jq .id dist/game.html.manifest.json | sed -E 's/^"(.*)"$/\1/')"
if [ -z "$GAME_ID" ];
    then echo "ERROR: Game ID not found in manifest"; exit 1
fi

git config --global user.email "git@qrgamestudio.com"
git config --global user.name "QR Bot"

git clone git@github.com:QRGameStudio/repo-games.git
DIR_GAME="repo-games/$GAME_ID"
if [ -d "$DIR_GAME" ]; then
  rm -r "$DIR_GAME"
fi
mkdir "$DIR_GAME"
cp dist/* "$DIR_GAME"
cd repo-games
git add "$GAME_ID"
git commit -m "chore: automatic build of $GAME_ID"
git push
