#!/bin/bash

### This script executed in a git repository list the maintenance branchs with some numbers

################################## Tool functions ##################################

function get_rellog() #args = current branch
{
    RELLOG=`git log -M --stat=1000,1000 $1 --not master | grep "|"`
}

############################## General info on project ##############################
REPONAME=`pwd | rev | cut -d '/' -f 1 | rev`
NBCOMMITS=`git log --format=oneline --all | wc -l`
NBRENAMES=`git log -M --stat=1000,1000 --all | grep "=>" | wc -l`
NBFILES=`git ls-tree -r --name-only HEAD | wc -l`
BRANCH=`git branch -r | sed '/->/d' | sed -e 's/^ *//g'`
NBBRANCH=`echo -e "$BRANCH" | wc -l` 
TAGS=`git tag | xargs -I@ git log --format=format:"%ai @%n" -1 @ | sort -V | cut -d ' ' -f 4`
NBTAGS=`echo -e "$TAGS" | wc -l`
echo ""
echo "PROJECT: $REPONAME, maintenance branchs"
echo ""
echo "Number of commits: $NBCOMMITS"
echo "Number of files: $NBFILES"
echo "Number of branch: $NBBRANCH"
echo "Number of release: $NBTAGS"
echo "Number of renames detected by git: $NBRENAMES"

echo ""

################################# Table Creation #####################################
echo ""
printf "%-50s" "branch:"
printf "%-20s" "commits:"
printf "%-20s" "renames:"
printf "%-20s" "files:"
printf "%-20s" "chance of renames:"
echo ""

CPT=1
while [ $CPT -le $NBBRANCH ]; do
    CURBRANCH=`echo -e "$BRANCH" | head -n$CPT | tail -n1`
    GETNUM=`echo -e "$CURBRANCH" | rev | cut -d '/' -f 1 | rev`
    COMMITS=`git log --format=oneline $CURBRANCH --not master | wc -l`
    get_rellog "$CURBRANCH"
    RENAMES=`echo -e "$RELLOG" | grep "=>" | wc -l`
    NBMODFILES=`echo -e "$RELLOG" | wc -l`
    if [[ $GETNUM == "master" ]]; then
	COMMITS=`git log --format=oneline $CURBRANCH | wc -l`
	RENAMES=`git log -M --stat=1000,1000 $CURBRANCH | grep "=>" | wc -l`
	NBMODFILES=`git log -M --stat=1000,1000 $CURBRANCH | grep "|" | wc -l`
    fi
    
    printf "%-50s" $CURBRANCH
    printf "%-20s" $COMMITS
    printf "%-20s" $RENAMES
    printf "%-20s" `git ls-tree -r --name-only $CURBRANCH | wc -l`
    if [ $NBMODFILES -gt 0 ]; then
	PRCHANCERENAMES=$(($RENAMES*100/$NBMODFILES))
    else
	PRCHANCERENAMES=0
    fi
    printf "%-20s" $PRCHANCERENAMES%
    echo ""
    CPT=$(($CPT+1))
done    

echo ""
echo ";;"
echo ""
