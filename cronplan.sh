#!/bin/bash

# cronplan - simple crontab tasks scheduling from command-line
# 2020, Laurent Ghigonis <ooookiwi@gmail.com>

PROGNAME="$(basename $0)"
PROGPATH="$(realpath $0)"
TMP="/tmp"

usageexit() {
	cat <<-_EOF
usage: $PROGNAME <action> [<taskname> [<args>]]
actions:
   add <taskname> HH:MM [-d] [-s <minutes>] <cmd>
      -d : repeat daily
      -s <minutes> : auto-snooze before executing command
   snooze <taskname> <minutes>
   time <taskname>
   del <taskname>
   list
_EOF
	exit 1
}

task_add() {
	tmp="$(mktemp $TMP/cronplan.XXXXXX)"
	IFS=: read hour minutes <<< $time
	[ -z "$hour" -o -z "$minutes" ] && echo "error: cannot add task, invalid time format: $time" && exit 1
	hour="$(printf "%d" $hour)"
	minutes="$(printf "%d" $minutes)"
	crontab -l > $tmp ||true
	echo "$minutes $hour * * * $PROGPATH exec $taskname $repeat $autosnooze '$cmd'" >> $tmp
	crontab $tmp
	rm $tmp
}

task_present() {
	crontab -l |grep -q "$PROGNAME exec $taskname" || return 1
	return 0
}

task_read_cron() {
	task_present $taskname || (echo "error: cannot read task, task '$taskname' is not in crontab"; exit 1)
	task="$(crontab -l |grep "$PROGNAME exec $taskname")"
	minute=$(echo "$task" |cut -d' ' -f1)
	hour=$(echo "$task" |cut -d' ' -f2)
	time="$hour:$minute"
	eval set -- "$(echo "$task" |cut -d' ' -f9-)"
	repeat="$1"
	autosnooze="$2"
	cmd="$3"
}

task_read_args() {
	task="$@"
	taskname=$1; time=$2; shift 2
	repeat="no"
	autosnooze="0"
	while :; do case $1 in
		-d) repeat="daily"; shift ;;
		-s) autosnooze="$2"; shift 2 ;;
		-*) usageexit ;;
		*) break ;;
	esac done
	[ $# -ne 1 ] && usageexit
	cmd="$1"
}

task_del() {
	task_present $taskname || (echo "error: cannot delete task, task '$taskname' is not in crontab"; exit 1)
	tmp="$(mktemp $TMP/cronplan.XXXXXX)"
	crontab -l |grep -v "$PROGNAME exec $taskname" > $tmp ||true
	crontab $tmp
	rm $tmp
}

task_snooze() {
	snooze_minutes=$1
	IFS=: read hour minutes <<< $time
	total_minutes=$(($minutes + $snooze_minutes))
	minutes=$(($total_minutes % 60))
	total_hour=$(($hour + ($total_minutes / 60)))
	hour=$(($total_hour % 24))
	time="$hour:$minutes"
	task_del
	task_add
}

unwind() {
	[ -n "$tmp" -a -e "$tmp" ] && rm $tmp ||true
}

set -e

[ $# -lt 1 ] && usageexit
action=$1; shift
umask 077
trap unwind EXIT

case $action in
a*)
	[ $# -lt 3 ] && usageexit
	task_read_args "$@"
	task_present && echo "error: cannot add task, task is already in crontab: $taskname" && exit 1
	task_add
	echo "task '$taskname' added"
	;;
s*)
	[ $# -ne 2 ] && usageexit
	taskname=$1
	snooze_minutes=$2
	task_read_cron
	task_snooze $snooze_minutes
	echo "task '$taskname' delayed of $snooze_minutes minutes: new time $time"
	;;
t*)
	[ $# -ne 1 ] && usageexit
	taskname=$1
	task_read_cron
	echo "$time"
	;;
d*)
	[ $# -ne 1 ] && usageexit
	taskname=$1
	task_del
	echo "task '$taskname' deleted"
	;;
l*)
	crontab -l |grep "$PROGNAME" ||true
	;;
exec)
	# used internally by the crontask
	[ $# -lt 4 ] && usageexit
	taskname="$1"
	repeat="$2"
	autosnooze="$3"
	cmd="$4"
	[ $autosnooze != "0" ] && task_read_cron && task_snooze $autosnooze ||true
	/bin/sh -c "$cmd" ||true
	[ $autosnooze = "0" -a $repeat = "no" ] && task_del ||true
	;;
*)
	usageexit
	;;
esac
