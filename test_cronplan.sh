#!/bin/bash

CRONPLAN="$(dirname $0)/cronplan.sh"
TMP="/tmp"

_test_cronplan_unwind() {
	$CRONPLAN del testtask >/dev/null
	rm -f $testfile
}

test_cronplan_1_addsnoozedel() {
	testfile="$TMP/test_cronplan_1_addsnoozedel"
	action="touch $testfile"
	rm -f $testfile
	trap _test_cronplan_unwind EXIT

	# add task
	$CRONPLAN add testtask 01:00 "$action" >/dev/null
	[ $? -ne 0 ] && return 10

	# list tasks
	$CRONPLAN list >/dev/null
	[ $? -ne 0 ] && return 20
	found=$($CRONPLAN list |grep "$CRONPLAN exec testtask" |wc -l)
	[ "$found" != "1" ] && return 21

	# get task time
	time=$($CRONPLAN time testtask)
	[ $? -ne 0 ] && return 30
	[ "$time" != "1:0" ] && return 31

	# check cron time
	minute=$(crontab -l |grep "$CRONPLAN exec testtask" |cut -d' ' -f1)
	[ "$minute" != "0" ] && return 40
	hour=$(crontab -l |grep "$CRONPLAN exec testtask" |cut -d' ' -f2)
	[ "$hour" != "1" ] && return 41

	# snooze task
	$CRONPLAN snooze testtask 10 >/dev/null
	[ $? -ne 0 ] && return 50

	# check cron time after snooze
	minute=$(crontab -l |grep "$CRONPLAN exec testtask" |cut -d' ' -f1)
	[ "$minute" != "10" ] && return 60
	hour=$(crontab -l |grep "$CRONPLAN exec testtask" |cut -d' ' -f2)
	[ "$hour" != "1" ] && return 61

	# snooze task bis
	$CRONPLAN snooze testtask 60 >/dev/null
	[ $? -ne 0 ] && return 70

	# check cron time after snooze bis
	minute=$(crontab -l |grep "$CRONPLAN exec testtask" |cut -d' ' -f1)
	[ "$minute" != "10" ] && return 80
	hour=$(crontab -l |grep "$CRONPLAN exec testtask" |cut -d' ' -f2)
	[ "$hour" != "2" ] && return 81

	# simulate task execution
	exec_cmd="$(crontab -l |grep "$CRONPLAN exec testtask" |cut -d' ' -f6-)"
	/bin/sh -c "$exec_cmd"
	[ $? -ne 0 ] && return 90
	[ ! -e $testfile ] && return 91
	rm -f $testfile

	# check task was deleted on execution
	found=$(crontab -l |grep "$CRONPLAN exec testtask" |wc -l)
	[ "$found" != "0" ] && return 100

	return 0
}

test_cronplan_2_autosnooze() {
	testfile="$TMP/test_cronplan_2_autosnooze"
	#action="touch $testfile"
	action="/bin/sh -c \"touch $testfile\""
	rm -f $testfile
	trap _test_cronplan_unwind EXIT

	# add task
	$CRONPLAN add testtask 01:00 -s 10 "$action" >/dev/null
	[ $? -ne 0 ] && return 10

	# simulate task execution
	#$CRONPLAN exec testtask 01:00 -s 10 $action
	exec_cmd="$(crontab -l |grep "$CRONPLAN exec testtask" |cut -d' ' -f6-)"
	/bin/sh -c "$exec_cmd"
	[ $? -ne 0 ] && return 20
	[ ! -e $testfile ] && return 21
	rm -f $testfile

	# check cron time after autosnooze
	minute=$(crontab -l |grep "$CRONPLAN exec testtask" |cut -d' ' -f1)
	[ "$minute" != "10" ] && return 30
	hour=$(crontab -l |grep "$CRONPLAN exec testtask" |cut -d' ' -f2)
	[ "$hour" != "1" ] && return 31

	# simulate task execution
	$CRONPLAN exec testtask 01:00 -s 10 $action
	[ $? -ne 0 ] && return 20
	[ ! -e $testfile ] && return 21
	rm -f $testfile

	# simulate task execution
	$CRONPLAN exec testtask 01:00 -s 10 $action
	[ $? -ne 0 ] && return 20
	[ ! -e $testfile ] && return 21
	rm -f $testfile

	# del task
	$CRONPLAN del testtask >/dev/null
	[ $? -ne 0 ] && return 40

	# check task was deleted
	found=$(crontab -l |grep "$CRONPLAN exec testtask" |wc -l)
	[ "$found" != "0" ] && return 50

	return 0
}

test_cronplan_1_addsnoozedel
ret=$?
[ $ret -ne 0 ] && echo "error: test_cronplan_1_addsnoozedel returned $ret" && exit 1
echo "test_cronplan_1_addsnoozedel OK"

test_cronplan_2_autosnooze
ret=$?
[ $ret -ne 0 ] && echo "error: test_cronplan_2_autosnooze returned $ret" && exit 1
echo "test_cronplan_2_autosnooze OK"

echo "all tests OK"
