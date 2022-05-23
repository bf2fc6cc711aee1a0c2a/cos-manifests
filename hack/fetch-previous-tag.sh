#!/usr/bin/env bash

git fetch --tags
git tag | tr - \~ | sort -V | tr \~ - | tail -2 | head -1 2>/dev/null
