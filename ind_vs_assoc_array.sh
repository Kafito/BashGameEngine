#! /bin/bash

#COLUMNS=320
#LINES=240

COLUMNS=$(tput cols)
LINES=$(tput lines)

ELEM_CNT=$((COLUMNS*LINES))

declare -A assoc

elems=$(seq 1 $ELEM_CNT)

clearStr=$(printf "_%.0s" $elems)

function assocTest {
  #for ((i = 0; i < ELEM_CNT; ++i)); do
  for i in $elems; do
    assoc[$i]=" "
  done

#  tput cup 0 0
#  printf %s "${assoc[@]}"
}

declare -a ind

function indTest {
  #for ((i = 0; i < ELEM_CNT; ++i)); do
  for i in $elems; do
    ind[$i]=" "
  done

#  tput cup 0 0
#  printf %s "${ind[@]}"
}

declare -a mixed
columns=$(seq 0 $((COLUMNS-1)))

anEmptyLine=$(printf "_%.0s" $columns)

for ((i = 0; i < LINES; ++i)); do
  mixed[$i]="$anEmptyLine"
done

function mixTest {
  for i in $elems; do
    line=$((i / COLUMNS))
    col=$((i % COLUMNS))
    str=${mixed[line]}
    mixed[$line]=${str:0:$col}"0"${str:$((col+1))}
  done
}

function tputTest {
  for i in $elems; do
    line=$((i / COLUMNS + 1))
    col=$((i % COLUMNS + 1))
    #tput cup $line $col
    #printf "\E[%i;%iH1" $line $col
    echo -en "\E[${line};${col}H1"
    #printf "1"
    #str=${mixed[line]}
    #mixed[$line]=${str:0:$col}"0"${str:$((col+1))}
  done
}

# # # # var test # # # # #
function evalTest {
  for i in $elems; do
    #eval "myArr$i='$i'" 
    declare -g "myArr$i"=$(($i % 10))
  done
}

function evalTest2 {
  for i in $elems; do
    eval "myArr$i='$((i % 10))'"
    #declare -g "myArr$i"=$i
  done
}

function printEval {
  tput cup 0 0
  rm -rf ./test.fifo
  mkfifo ./test.fifo
  tail -f ./test.fifo  &
  for i in $elems; do
    eval "printf \"\$myArr$i\"" >> ./test.fifo
  done
}

#echo "assoc:"; for t in {1..3}; do time { assocTest; echo; } ; read ; done
#echo "ind:";   for t in {1..3}; do time { indTest; echo; } ; read; done
#echo "mixed:"; for t in {1..3}; do time { mixTest; echo; } ; read; done
#echo "tput:"; for t in {1..3}; do time { tputTest; echo; } ; read; done
echo "eval:"; for t in {1..3}; do time { evalTest2; echo; } ; read; done
echo "peval:"; for t in {1..3}; do time { printEval; echo; }; read; done

#time { tput cup 0 0; printf "$clearStr"; }

