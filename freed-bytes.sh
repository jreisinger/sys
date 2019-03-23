#!/bin/bash
# How many bytes would we free by removing $FILE_NAMES older than $OLDER_THAN

# find options
OLDER_THAN=180          # -mtime
FILE_NAMES='*.tgz'      # -name

function show_usage {
        echo "Usage: $0 directory"
        exit 1
}

if [ $# -ne 1 ]; then
        show_usage
fi

if [ -d $1 ]; then
        DIR=$1
else
        show_usage
fi

for size in `find $DIR -mtime +$OLDER_THAN -name "$FILE_NAMES" | xargs ls -l | perl -ane 'print $F[4] . "\n"'`
do 
        tot=$(($tot + $size))
done

echo "By removing files older than $OLDER_THAN days from '$DIR', $tot bytes would bee freed."
