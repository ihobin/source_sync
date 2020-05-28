#/bin/bash
TTY=$(tty)
UNISON=/usr/bin/unison
INOTIFYWAIT=/usr/bin/inotifywait

# conf
PRF=sync.prf
SRC_DIR=/home/hobin/dev
IGNORES="^25/* ^26/* ^run/* ^build.mk/* .unison*"

# init
echo -e "Began: $(date)\nInotify: init"
$UNISON $PRF
echo -e "Ended: $(date)\n"

# is running
if [[ $(ps -ef | grep -v grep | grep -c inotifywait) -gt 0 ]]; then 
    echo inotifywait is running
    exit 0
fi

is_ignore()
{
    for reg in $1; do
        if [[ $(echo "$2" | grep -c -E "$reg") -gt 0 ]]; then
            return 0
        fi
    done
    return 1
}

# inotifywait
$INOTIFYWAIT -mrq -e create,delete,modify,move $SRC_DIR | while read event; do
    path=$(echo $event | awk '{print $1}')
    path=${path/$SRC_DIR\//}
    file=$(echo $event | awk '{print $3}')
    
    if is_ignore "$IGNORES" "$path$file"; then
        newline=1
        size=($(stty size -F $TTY))
        printf "%-${size[1]}s\r" "Ignore file: $SRC_DIR/$path$file"
        continue
    fi
    if [[ $newline -eq 1 ]]; then
        newline=0
        printf "\n"
    fi
    
    echo -e "Began: $(date)\nInotify: $event"
    $UNISON $PRF -path "$path$file"
    echo -e "Ended: $(date)\n"
done
