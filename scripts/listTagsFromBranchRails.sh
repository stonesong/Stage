#!/bin/bash

###List the tags contained in the branch gave in argument

BRANCH=$1
TAGS=`git tag | sed '/guides/d'`
TAGS=`echo "$TAGS" | xargs -I@ git log --format=format:"%ai @%n" -1 @ | sort -V | cut -d ' ' -f 4`
NBTAGS=`echo -e "$TAGS" | wc -l`
BRANCHLOG=`git log --format=oneline $BRANCH --not master`
if [[ $BRANCH == "origin/master" ]]; then
    BRANCHLOG=`git log --format=oneline $BRANCH`
fi

LIST=""
CPT=1
while [ $CPT -le $NBTAGS ]; do
    TAG=`echo -e "$TAGS" | head -n$CPT | tail -n1`
    TAGLOG=`git log -n 1 --format=oneline "$TAG" | cut -d ' ' -f 1`
    BOOL=`echo -e "$BRANCHLOG" | grep "$TAGLOG" | wc -l`
    if [ $BOOL -eq 1 ]; then
	LIST=$LIST$TAG"\n"
    fi
    CPT=$(($CPT+1))
done
echo -e "$LIST"

