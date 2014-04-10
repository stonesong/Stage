#!/bin/bash

### This script executed in a git repository return a csv format

################################## Tool functions ##################################

function get_rellog() #release log between revision range (args = startCommit, endCommit)
{
    RELLOG=`git log -M --stat=1000,1000 --format=format:"%H" $1..$2 | grep "|"`
}

function get_branchRellog() #args = current branch
{
    RELLOG=`git log -M --stat=1000,1000 --format=format:"%H" $1 --not master | grep "|"`
}

function get_masterRellog()
{
    RELLOG=`git log -M --stat=1000,1000 --format=format:"%H" origin/master | grep "|"`
}

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
	PRRENAMED=$(($NBRENAMED*10000/$NBMODIFIED))
    else
	PRRENAMED=0
    fi
}

function get_nbCommits()# args = startCommit, endCommit
{
    NBCOMMITS=`git log --format=oneline $1..$2 | wc -l` 
}

function get_nbBranchCommits()# args = current branch
{
    NBCOMMITS=`git log --format=oneline $1 --not master | wc -l` 
}

function get_nbMasterCommits()
{
    NBCOMMITS=`git log --format=oneline origin/master | wc -l` 
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
    PRCHANCERENAMES=$(($1*10000/$2))
} 

##################################### Tags ##########################################

function get_tagList() #args = branch
{
    local BRANCH=$1
    local TAGS=`git tag`
    #TAGS=`echo -e "$TAGS" | sed '/guides/d'`
    local TAGS=`echo -e "$TAGS" | xargs -I@ git log --format=format:"%ai @%n" -1 @ | sort -V | cut -d ' ' -f 4`
    local NBTAGS=`echo -e "$TAGS" | wc -l`
    local BRANCHLOG=`git log --format=oneline $BRANCH --not master`
    if [[ $BRANCH == "origin/master" ]]; then
	local BRANCHLOG=`git log --format=oneline $BRANCH`
    fi
    local LLIST=""
    CPT=1
    while [ $CPT -le $NBTAGS ]; do
	local TAG=`echo -e "$TAGS" | head -n$CPT | tail -n1`
	local TAGLOG=`git log -n 1 --format=oneline "$TAG" | cut -d ' ' -f 1`
	 BOOL=`echo -e "$BRANCHLOG" | grep "$TAGLOG" | wc -l`
	if [ $BOOL -eq 1 ]; then
	    local LLIST=$LLIST$TAG"\n"
	fi
	CPT=$(($CPT+1))
    done
    TAGLIST=$LLIST
}

function get_majorReleases() #args= file containing list of major releases on master branch
{
    RELLIST=`cat "$1"`
}

############################## General info on project ##############################

BRANCHES=`git branch -r | sed '/->/d' | sed -e 's/^ *//g'`
NBBRANCH=`echo -e "$BRANCHES" | wc -l`
REPONAME=`pwd | rev | cut -d '/' -f 1 | rev`


################################# Table Creation ####################################
#echo "$REPONAME"
printf "#Name;#Type;#nb of commits;#nb of renames;#nb of files;#%% of renames among all file modifications;#%% of files renamed;"
echo ""
CPT=1
while [ $CPT -le $NBBRANCH ]; do
    CURBRANCH=`echo -e "$BRANCHES" | head -n$CPT | tail -n1`
    if [[ $CURBRANCH == "origin/master" ]]; then
        get_nbMasterCommits
       	get_masterRellog
	get_tagList "$CURBRANCH"
	get_majorReleases "majorReleaseList"
	RELLISTSIZE=`echo -e "$RELLIST" | wc -l`
	FIRSTCOMMIT=`git log --format=oneline --reverse $CURBRANCH | head -1 | cut -d ' ' -f 1`

	##before first tag
	FIRSTRELEASE=`echo -e "$RELLIST" | head -n1 | tail -n1`
	get_nbCommits "$FIRSTCOMMIT" "$FIRSTRELEASE"
	get_rellog "$FIRSTCOMMIT" "$FIRSTRELEASE"
	get_nbRenames "$RELLOG"
	get_nbFiles "$FIRSTRELEASE"
	get_nbModifiedFiles "$RELLOG"
	get_prChanceOfRenames "$NBRENAMES" "$NBMODFILES"
	get_prRenamed "$RELLOG" "$NBMODFILES"
	printf "before first release tag;INIT;$NBCOMMITS;$NBRENAMES;$NBFILES;$PRCHANCERENAMES;$PRRENAMED;"
	echo""

	##first tag to last tag
	I=1
	while [ $I -le $(($RELLISTSIZE-1)) ]; do
	    RELEASE1=`echo -e "$RELLIST" | head -n$I | tail -n1`
	    RELEASE2=`echo -e "$RELLIST" | head -n$(($I+1)) | tail -n1`
	    get_nbCommits "$RELEASE1" "$RELEASE2"
	    get_rellog "$RELEASE1" "$RELEASE2"
	    get_nbRenames "$RELLOG"
	    get_nbFiles "$RELEASE2"
	    get_nbModifiedFiles "$RELLOG"
	    get_prChanceOfRenames "$NBRENAMES" "$NBMODFILES"
	    get_prRenamed "$RELLOG" "$NBMODFILES"
	    printf "$RELEASE1;DEV;$NBCOMMITS;$NBRENAMES;$NBFILES;$PRCHANCERENAMES;$PRRENAMED;"
	    echo ""
	    I=$(($I+1))
	done

	##Last tag to head
	RELEASE1=`echo -e "$RELLIST" | head -n$CPT | tail -n1`
	get_nbCommits "$RELEASE1" "$CURBRANCH"
	get_rellog "$RELEASE1" "$CURBRANCH"
	get_nbRenames "$RELLOG"
	get_nbFiles "$CURBRANCH"
	get_nbModifiedFiles "$RELLOG"
	get_prChanceOfRenames "$NBRENAMES" "$NBMODFILES"
	get_prRenamed "$RELLOG" "$NBMODFILES"
	printf "$RELEASE1(last release !);DEV;$NBCOMMITS;$NBRENAMES;$NBFILES;$PRCHANCERENAMES;$PRRENAMED;"
	echo""

    else #maintenance branch
	get_nbBranchCommits "$CURBRANCH"
	get_branchRellog "$CURBRANCH"
	get_nbRenames "$RELLOG"
	get_nbFiles "$CURBRANCH"
	get_nbModifiedFiles "$RELLOG"
	get_prChanceOfRenames "$NBRENAMES" "$NBMODFILES"
	get_prRenamed "$RELLOG" "$NBMODFILES"
	printf "$CURBRANCH;MAINT;$NBCOMMITS;$NBRENAMES;$NBFILES;$PRCHANCERENAMES;$PRRENAMED;"	
	echo ""
    fi
    CPT=$(($CPT+1))
done    

