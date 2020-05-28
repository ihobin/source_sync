#/bin/bash

UNISON=/usr/bin/unison
INOTIFY=/usr/bin/inotifywait

PRF=sync.prf
SRC_DIR=/home/hobin/dev
LOG_DIR=/home/hobin/unison
IGNORE="^25/* ^26/* ^run/* ^build.mk/* .unison*"

# init
logfile=$LOG_DIR/inotify_$(date +%Y%m%d).log
echo -e "began: $(date)\ninotify: init" >> $logfile
$UNISON $PRF >> $logfile 2>&1
echo -e "ended: $(date)\n" >> $logfile

# inotifywait
if [ $(ps -ef | grep -v grep | grep -c inotifywait) -lt 1 ]; then
  $INOTIFY -mrq -e create,delete,modify,move $SRC_DIR | while read event; do
    path=$(echo $event | awk '{print $1}')
    path=${path/$SRC_DIR\//}
    file=$(echo $event | awk '{print $3}')
	if [ -a "$SRC_DIR/$path$file" ]; then
	  ignore=0
	  for reg in $IGNORE; do
	    if [ $(echo "$path$file" | grep -E "$reg" -c) -gt 0 ]; then
			ignore=1
			break
		fi
      done
	  if [ $ignore -eq 1 ]; then continue; fi
      logfile=$LOG_DIR/inotify_$(date +%Y%m%d).log
      echo -e "began: $(date)\ninotify: $event" >> $logfile
	  $UNISON $PRF -path "$path$file" >> $logfile 2>&1
	  echo -e "ended: $(date)\n" >> $logfile
	fi
  done
fi
