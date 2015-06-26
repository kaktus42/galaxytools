#!/bin/bash

EXT=$1

mv output/process_radtags.log output/Report.log
mv output/*.discards output/Discards.${EXT}.discards
mkdir splits
mv output/sample_* splits
#ls -lah output splits
for i in splits/*.fq; do mv "$i" "${i/.fq}".${EXT}; done
