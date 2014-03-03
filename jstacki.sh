  1 #!/bin/bash
  2
  3 if [ $# -eq 0 ]; then
  4     echo >&2 "Usage: jstackSeries <pid> <<count> delay> "
  5     echo >&2 "    Defaults: count = 3, delay = 0.5 (seconds)"
  6     exit 1
  7 fi
  8 pid=$1          # required
  9 count=${2:-3}  # defaults to 3 times
 10 delay=${3:-0.5} # defaults to 0.5 seconds
 11 while [ $count -gt 0 ]
 12 do
 13      jstack -l $pid >/tmp/jstack.$pid.$count
 14     sleep $delay
 15     let count--
 16     echo -n "."
 17 done
~
