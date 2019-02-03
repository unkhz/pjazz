#!/bin/bash

rm -rf dist
mkdir dist
zip -j dist/pjazz.zip src/PJAZZ.BAT build/PJAZZ.EXE songs/*.JZZ
cp -a node_modules/js-dos/dist/*.js dist/
cp -a node_modules/js-dos/dist/*.js.* dist/
cp -a public/* dist/