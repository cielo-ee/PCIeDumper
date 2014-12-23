#!/bin/sh

DAY=`date +%Y%m%d-%H%M%S`

./pciedump.pl 1> ./test/result_${DAY}.txt
cat ./test/result_${DAY}.txt

RESULT= `diff ./test/result_${DAY}.txt ./test/result.txt`

echo "${RESULT}"

if test "${RESULT}" = ""; 
    then
       echo "OK"
    else
       echo "NG"
fi