#!/bin/bash
# Hardcoded Values Here:
USER_AGENT="UserAgentv1.0 Here"
COOKIEFILE="cookies.txt"
OUTPUTLOC="submissionids.txt"

# -- This Section covers arguments and passes them --
# getopts string
opts="rv:"
cmd(){ echo `basename $0`; }
for pass in 1 2; do
    while [ -n "$1" ]; do
        case $1 in
            --) shift; break;;
            -*) case $1 in
                -r|--subreddit)      SUBREDDIT=$2; shift;;
                -v|--verbose)  VERBOSE=$(($VERBOSE + 1));;
                --*)           error $1;;
                -*)            if [ $pass -eq 1 ]; then ARGS="$ARGS $1";
                               else error $1; fi;;
                esac;;
            *)  if [ $pass -eq 1 ]; then ARGS="$ARGS $1";
                else error $1; fi;;
        esac
        shift
    done
    if [ $pass -eq 1 ]; then ARGS=`getopt $opts $ARGS`
        if [ $? != 0 ]; then usage; exit 2; fi; set -- $ARGS
    fi
done
# Handle positional arguments
if [ -n "$*" ]; then
    echo "`cmd`: Extra arguments -- $*"
    echo "Try '`cmd` -h' for more information."
    exit 1
fi

# Set verbosity
if [ "0$VERBOSE" -eq 0 ]; then
VERB=0
fi
if [ "0$VERBOSE" -eq 1 ]; then
VERB=1
fi
# Get the first page
DATA="$(curl -s -A $USER_AGENT -b $COOKIEFILE https://www.reddit.com/r/$SUBREDDIT/.json)"
AFTER="$(echo "$DATA" | jq '.data.after')"
# Parse first page's JSON for the URL, then strip out everything except ID
if [ "$VERB" = 1 ]; then
	echo "$DATA" | jq '.data.children[].data.url' | grep reddit | sed -e 's/"https:\/\/www\.reddit\.com\/r\/'$SUBREDDIT'\/comments\///g' | sed -e 's/\/.*//g' | tee "$OUTPUTLOC"
else
	echo "$DATA" | jq '.data.children[].data.url' | grep reddit | sed -e 's/"https:\/\/www\.reddit\.com\/r\/'$SUBREDDIT'\/comments\///g' | sed -e 's/\/.*//g' >> "$OUTPUTLOC"
fi
echo "Page 1 Scraped and IDs Parsed"
# Iterate over listing and get all links
COUNT=2
while [[ $AFTER != "null" ]]; do
VARS="$(curl -s -A $USER_AGENT -b $COOKIEFILE https://www.reddit.com/r/$SUBREDDIT/.json?after=${AFTER:1:-1})"
 # Download, parse, and save
if [ "$VERB" = 1 ]; then
	echo "$VARS" | jq '.data.children[].data.url' | grep reddit | sed -e 's/"https:\/\/www\.reddit\.com\/r\/'$SUBREDDIT'\/comments\///g' | sed -e 's/\/.*//g' | tee -a "$OUTPUTLOC"
else
	echo "$VARS" | jq '.data.children[].data.url' | grep reddit | sed -e 's/"https:\/\/www\.reddit\.com\/r\/'$SUBREDDIT'\/comments\///g' | sed -e 's/\/.*//g' >> "$OUTPUTLOC"
fi
AFTER="$(echo "$VARS" | jq '.data.after')"
 echo "Page $COUNT Scraped and IDs Parsed"
 COUNT=`expr $COUNT + 1`
done
