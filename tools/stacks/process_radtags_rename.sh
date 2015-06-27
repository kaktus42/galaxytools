#!/bin/bash

EXT=$1

mv output/*.discards output/discards.discards
mkdir splits
mv output/sample_* splits
#ls -lah output splits
for i in splits/*.fq; do mv "$i" "${i/.fq}".${EXT}; done
