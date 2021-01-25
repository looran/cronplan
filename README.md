## cronplan - simple crontab tasks scheduling from command-line

cronplan is a shell script to easily add, delete and snooze crontab entries by task name.

### Examples

**Create a task**
``` bash
$ cronplan add reveil 06:07 "mpv /tmp/dringdring.wav"
task 'reveil' added
```

**Snooze a task for 10 minutes**
``` bash
$ cronplan snooze reveil 10
task 'reveil' delayed of 10 minutes: new time 6:17
```

**List tasks**
``` bash
$ cronplan list
17 6 * * * /usr/local/bin/cronplan exec reveil no 0 'mpv /tmp/dringdring.wav'
```

**Delete a task**
``` bash
$ cronplan del reveil
task 'reveil' deleted
```

### Usage

``` bash
usage: cronplan <action> [<taskname> [<args>]]
actions:
   add <taskname> HH:MM [-d] [-sS <minutes>] <cmd>
      -d : repeat daily
      -s <minutes> : auto-snooze before executing command
   snooze <taskname> <minutes>
   time <taskname>
   del <taskname>
   list
```

### Install

``` bash
sudo make install
```

### Compatibity

Cronplan has been tested on Linux using:
* cronie 1.5.5
* crond from busybox v1.33.0

### Unit tests

``` bash
$ ./test_cronplan.sh 
test_cronplan_1_addsnoozedel OK
test_cronplan_2_autosnooze OK
all tests OK
```
