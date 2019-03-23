#!/bin/bash
# How many bytes would we free by removing files older than $OLDER_THAN.

# find options
OLDER_THAN=180          # -mtime

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

for size in `find $DIR -type f -mtime +$OLDER_THAN -print0 | xargs -0 ls -l | perl -lane 'print $F[4]'`
do
        tot=$(($tot + $size))
done

echo "By removing files older than $OLDER_THAN days from '$DIR', $tot bytes would bee freed."
