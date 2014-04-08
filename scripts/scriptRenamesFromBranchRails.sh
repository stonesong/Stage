#!/bin/bash

###This Script was mad to count renames and commits between releases on the specified branch gave in argument
BRANCH=$1

###################################### Tool functions #####################################################

function get_prRenamed() #percentage of renamed files (arguments = release Log, number of modified files)
{
    if [ $2 -gt 1 ]; then
	declare -A hashrenames
	declare -A hashmodified
	local CPT=1
	local HASHMODSIZE=0
	local HASHRENSIZE=0
	local LOG=$1
	local WCOND=$2
	while [ $CPT -le $WCOND ]; do
	    local LINE=`echo -e "$LOG" | head -n$CPT | tail -n1`
	    if [ `echo -e "$LINE" | grep "=>" | wc -l` -eq 1 ]; then
		local FILE1=`echo -e "$LINE" | sed 's/^ *\(.*\){\(.*\) => \(.*\)}\([^ ]*\)\(.*\)/\1\2\4/'`
		local FILE2=`echo -e "$LINE" | sed 's/^ *\(.*\){\(.*\) => \(.*\)}\([^ ]*\)\(.*\)/\1\3\4/'`
		local COND1=`echo -e "${hashrenames["$FILE1"]}"`
		if [ "$COND1" != "$FILE1" ];then
		    local HASHRENSIZE=$(($HASHRENSIZE+1))
		    local HASHMODSIZE=$(($HASHMODSIZE+1))
		fi
		hashrenames=( [$FILE2]=$FILE2 )
	    else
		local FILE=`echo -e "$LINE" | sed -e 's/^ *//g' | cut -d ' ' -f 1`
		local COND=`echo -e "${hashmodified["$FILE"]}"`
		if [ "$COND" != "$FILE" ];then
		    local HASHMODSIZE=$(($HASHMODSIZE+1))
		    hashmodified=( [$FILE]=$FILE )
		fi
	    fi
	    local CPT=$(($CPT+1))
	done
	local NBMODIFIED=$HASHMODSIZE
	local NBRENAMED=$HASHRENSIZE
	PRRENAMED=$(($NBRENAMED*100/$NBMODIFIED))
    else
	PRRENAMED=0
    fi
}

function get_rellog() #release log between revision range (args = startCommit, endCommit)
{
    RELLOG=`git log -M --stat=1000,1000 $1..$2 | grep "|"`
}

function get_nbCommits()# args = startCommit, endCommit
{
    NBCOMMITS=`git log --format=oneline $1..$2 | wc -l` 
}

function get_nbRenames() #args = release log
{
    NBRENAMES=`echo -e "$1" | grep "=>" | wc -l` 
}

function get_nbModifiedFiles() #args = release log
{
    NBMODFILES=`echo -e "$1" | wc -l`
}

function get_nbFiles() #args = version
{
    NBFILES=`git ls-tree -r --name-only $1 | wc -l`  
}

function get_prChanceOfRenames() #args = nb renames, nb modified files
{
    PRCHANCERENAMES=$(($1*100/$2))
}


################ Get info on tags from script listTagsFromBranch<project>.sh ##############################
TAGS=`./listTagsFromBranchRails.sh "$BRANCH"`
NBTAGS=`echo -e "$TAGS" | wc -l`

####################################### General info on branch ############################################

BRANCHLOG=`git log --format=oneline $BRANCH --not master`
FIRSTCOMMIT=`git log --format=oneline --reverse $BRANCH --not master | head -1 | cut -d ' ' -f 1`
if [[ $BRANCH == "origin/master" ]]; then
    BRANCHLOG=`git log --format=oneline $BRANCH`
    FIRSTCOMMIT=`git log --format=oneline --reverse $BRANCH | head -1 | cut -d ' ' -f 1`
fi

get_nbCommits "$FIRSTCOMMIT" "$BRANCH"
get_nbFiles "$BRANCH"
NBRENAMES=`git log -M --stat=1000,1000 $FIRSTCOMMIT..$BRANCH | grep "=>" | wc -l`

echo ""
echo "On Branch $BRANCH:"
echo ""
echo "Number of commits: $NBCOMMITS"
echo "Number of files: $NBFILES"
echo "Number of releases: $NBTAGS"
echo "Number of renames detected by git: $NBRENAMES"
echo ""

######################################### Table creation #################################################

echo "" 
printf "%-50s" "release:"
printf "%-20s" "commits:"
printf "%-20s" "renames:"
printf "%-20s" "files:"
printf "%-20s" "chance of renames:"
printf "%-20s" "renamed files:"
echo ""

##before first tag
printf "%-40s" "before first tag"
FIRSTRELEASE=`echo -e "$TAGS" | head -n1 | tail -n1`
get_nbCommits "$FIRSTCOMMIT" "$FIRSTRELEASE"
get_rellog "$FIRSTCOMMIT" "$FIRSTRELEASE"
get_nbRenames "$RELLOG"
get_nbFiles "$FIRSTRELEASE"
get_nbModifiedFiles "$RELLOG"
printf "%-20s" $NBCOMMITS
printf "%-20s" $NBRENAMES
printf "%-20s" $NBFILES
get_prChanceOfRenames "$NBRENAMES" "$NBMODFILES"
printf "%-20s" $PRCHANCERENAMES%
get_prRenamed "$RELLOG" "$NBMODFILES"
printf "%-20s" $PRRENAMED%
echo""

##first tag to last tag
CPT=1
while [ $CPT -le $(($NBTAGS-1)) ]; do
    RELEASE1=`echo -e "$TAGS" | head -n$CPT | tail -n1`
    RELEASE2=`echo -e "$TAGS" | head -n$(($CPT+1)) | tail -n1`
    get_nbCommits "$RELEASE1" "$RELEASE2"
    get_rellog "$RELEASE1" "$RELEASE2"
    get_nbRenames "$RELLOG"
    get_nbFiles "$RELEASE2"
    get_nbModifiedFiles "$RELLOG"
    printf "%-40s" $RELEASE1
    printf "%-20s" $NBCOMMITS
    printf "%-20s" $NBRENAMES
    printf "%-20s" $NBFILES
    get_prChanceOfRenames "$NBRENAMES" "$NBMODFILES"
    printf "%-20s" $PRCHANCERENAMES%
    get_prRenamed "$RELLOG" "$NBMODFILES"
    printf "%-20s" $PRRENAMED%
    
    echo ""
    CPT=$(($CPT+1))
done

##Last tag to head
RELEASE1=`echo -e "$TAGS" | head -n$CPT | tail -n1`
get_nbCommits "$RELEASE1" "$BRANCH"
get_rellog "$RELEASE1" "$BRANCH"
get_nbRenames "$RELLOG"
get_nbFiles "$BRANCH"
get_nbModifiedFiles "$RELLOG"
printf "%-40s" $RELEASE1
printf "%-20s" $NBCOMMITS
printf "%-20s" $NBRELRENAMES
printf "%-20s" $NBFILES
get_prChanceOfRenames "$NBRENAMES" "$NBMODFILES"
printf "%-20s" $PRCHANCERENAMES%
get_prRenamed "$RELLOG" "$NBMODFILES"
printf "%s" $PRRENAMED%
printf " (latest release !)"
echo""

echo ""
echo ""
echo ";;"
echo ""
