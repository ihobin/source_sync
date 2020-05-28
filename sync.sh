#/bin/bash
TTY=$(tty)
UNISON=/usr/bin/unison
INOTIFYWAIT=/usr/bin/inotifywait

# conf
PRF=sync.prf
SRC_DIR=/home/hobin/dev
LOG_DIR=/home/hobin/unison
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
        if [[ $(echo "$2" | grep -E "$reg" -c) -gt 0 ]]; then
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
    if [[ ! -a "$SRC_DIR/$path$file" ]]; then
        size=($(stty size -F $TTY))
        printf "%-${size[1]}s\r" "Not exists file: $SRC_DIR/$path$file"
        continue
    fi
    
    if is_ignore "$IGNORES" "$path$file"; then
        size=($(stty size -F $TTY))
        printf "%-${size[1]}s\r" "Ignore file: $SRC_DIR/$path$file"
        continue
    fi
    
    echo -e "Began: $(date)\nInotify: $event"
    $UNISON $PRF -path "$path$file"
    echo -e "Ended: $(date)\n"
done
