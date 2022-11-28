#!/usr/bin/env bash

function fetchTag()
{
    git clone -n https://github.com/bf2fc6cc711aee1a0c2a/cos-fleetshard.git ./fleetshard-for-tags
    cd ./fleetshard-for-tags/ || exit
    git fetch --tags
    result=$(git tag | tr - \~ | sort -V | tr \~ - | tail -2 | head -1 2>/dev/null)
    cd ..
    rm -rf ./fleetshard-for-tags
    echo "$result"
}

result=$(fetchTag)
echo $result