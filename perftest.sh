#! /bin/bash

COLUMNS=$(tput cols)
LINES=$(tput lines)

frameLines=3
defaultIFS="$IFS"

BUFFERLINES=$((LINES - (2 * frameLines)))
echo $((BUFFERLINES * COLUMNS))
function processSpawnTest {
  for ((i = 0; i < BUFFERLINES * COLUMNS; ++i ))
  do
    /bin/false  &
  done
}

aColumn=""
for column in $(seq 0 $((COLUMNS-1))); do
  #aColumn=$aColumn"# "
  aColumn=$aColumn". "
done

function stringClear {
  screen=""
  #for line in $(seq 0 $((LINES-1))); do
    #aColumn=$aColumn"\n"
  #done
  for line in $(seq 0 $((BUFFERLINES-1))); do
    #screen=$screen"$aColumn"
    screen=$screen"$aColumn"
  done
  #screen="$aColumn"
#screenBuffer=""
#for row in $(seq 1 $LINES); do
#  screenBuffer=$screenBuffer"\n$aColumn"
#done
}

stringClear

function printStringBuffer {
  tput cup $frameLines 0
  printf "$screen"
}

function setToString {
  local x=$1
  local y=$2
  local char=$3
  local pos=y*COLUMNS+x
  screen=${screen:0:$pos}"$char"${screen:$((pos+1))}
}

declare -a scr

function setTo {
# theStr="${theStr:0:4}A${theStr:5}"
    #tput cup $2 $1
    #printf $3
    #return
    local x=$1
    local y=$2
    local char=$3
    local pos=y*COLUMNS+x
    scr[$pos]=$char
}

function printBuffer {
  tput cup $frameLines 0
  local -n buffer=$1
  printf "%s" "${buffer[@]}"
}
allindices=$(seq 0 $((BUFFERLINES*COLUMNS-1)))
function clearBuffer {
  IFS=" "; read -a scr <<< "$screen"; IFS="$defaultIFS"

  #echo "${scr[@]}"
  #return
  #for column in $(seq 0 $((COLUMNS-1))); do
  #  for line in $(seq 0 $(( LINES - 1 - 2 * frameLines ))); do
  #    let pos="line*COLUMNS + column"
  #    scr[$pos]='_'
  #    #setTo $column $line '_'
  #  done
  #done
  #for i in $allindices; do
  #  scr[$i]='X'
  #done
}

function drawRect {
  local x_1=$1
  local y_1=$2
  local x_2=$3
  local y_2=$4
  local char=$5
  for (( c = x_1; c < x_2; ++c)); do
    local pos=y_1*COLUMNS+c
    scr[$pos]=$char
    local pos=y_2*COLUMNS+c
    scr[$pos]=$char
  done

  for (( r = y_1; r < y_2; ++r )); do
    local pos=r*COLUMNS+x_1
    scr[$pos]=$char
    local pos=r*COLUMNS+x_2
    scr[$pos]=$char
  done
}

function fillRect {
  local x_1=$1
  local y_1=$2
  local x_2=$3
  local y_2=$4
  local char=$5
  for (( l = y_1; l < y_2; ++l )); do
    for (( c= x_1; c < x_2; ++c )); do
      local pos=l*COLUMNS+c
      scr[$pos]=$char
    done
  done
}

function drawLine { # x1 y1 x2 y2 char
  if (( $3 < $1 )); then
    drawLine $3 $4 $1 $2 $5
    return
  fi
  local x_1=$1
  local x_2=$3
  local y_1=$2
  local y_2=$4
  local char=$5

  if (( y_2 >= y_1 )); then
    local ydist=y_2-y_1+1
    local xdist=x_2-x_1+1

    if ((ydist > xdist)); then
      local curInc=$((xdist / 2))
      local ind=0

      for (( line=y_1, col=x_1; line <= y_2; ++line)); do
        local pos=line*COLUMNS+col
        scr[$pos]="$ind"
        ((ind = (++ind)%10)) # debug
        ((curInc += xdist))
        if ((curInc / ydist > 0)); then
          ((curInc = curInc % ydist))
          ((col++))
        fi
      done
    else
      local curInc=$((ydist / 2))
      local ind=0

      for (( col=x_1, line=y_1; col <= x_2; ++col)); do
        local pos=line*COLUMNS+col
        scr[$pos]=" " #"$ind"
        ((ind = (++ind)%10)) # debug
        ((curInc += ydist))
        if ((curInc / xdist > 0)); then
          ((curInc = curInc % xdist))
          ((line++))
        fi
      done
    fi

  else
    let ydist="y_1 - y_2 + 1"
    let xdist="x_2 - x_1 + 1"

    if ((ydist > xdist)); then
      local line=$y_1
      local col=$x_1
      local curInc=$((xdist / 2))
      local ind=0
      while [ $line -ge $y_2 ]; do
        let local pos="line * COLUMNS + col"
        scr[$pos]="_" #$ind"
        ((line--))
        ((ind = (++ind)%10)) # debug
        ((curInc += xdist))
        if ((curInc / ydist > 0)); then
          ((curInc = curInc % ydist))
          ((col++))
        fi
      done
    else
      local line=$y_1
      local col=$x_1
      local curInc=$((ydist / 2))
      local ind=0
      while [ $col -le $x_2 ]; do
        let local pos="line * COLUMNS + col"
        scr[$pos]="_" #$ind"
        ((col++))
        ((ind = (++ind)%10)) # debug
        ((curInc += ydist))
        if ((curInc / xdist > 0)); then
          ((curInc = curInc % xdist))
          ((line--))
        fi
      done
    fi
  fi

}

function drawCircle { # cX cY rad char
  local cX=$1
  local cY=$2
  local rad=$3
  local char=$4

# Idea:
# x^2 + y^2 = M
# check right, down, right-down.
# goto and set field with value closest to M

  xRad=0
  yRad=$rad

   local y=$((cY - yRad))
   local x=$((cX + xRad))
   local pos=$((y*COLUMNS + x))
   scr[$pos]="$char"
   local y=$((cY + yRad))
   local x=$((cX + xRad))
   local pos=$((y*COLUMNS + x))
   scr[$pos]="$char"
   local y=$((cY - yRad))
   local x=$((cX - xRad))
   local pos=$((y*COLUMNS + x))
   scr[$pos]="$char"
   local y=$((cY + yRad))
   local x=$((cX - xRad))
   local pos=$((y*COLUMNS + x))
   scr[$pos]="$char"

  while (( $xRad < $rad || $yRad != 0 )) ; do
    right=$(( (xRad+1)**2 + (yRad)**2)) 
    down=$(( (xRad)**2 + (yRad-1)**2)) 
    rightdown=$(( (xRad+1)**2 + (yRad-1)**2)) 

    ((right = (right - rad**2)**2 ))
    ((down = (down - rad**2)**2 ))
    ((rightdown = (rightdown - rad**2)**2 ))

    if (( right <= down && right <= rightdown )); then
      (( xRad++ ))
    elif (( down <= right && down <= rightdown )); then
      (( yRad-- ))
    else
      (( xRad++ ))
      (( yRad-- ))
    fi
    local y=$((cY - yRad))
    local x=$((cX + xRad))
    local pos=$((y*COLUMNS + x))
    scr[$pos]="$char"
    local y=$((cY + yRad))
    local x=$((cX + xRad))
    local pos=$((y*COLUMNS + x))
    scr[$pos]="$char"
    local y=$((cY - yRad))
    local x=$((cX - xRad))
    local pos=$((y*COLUMNS + x))
    scr[$pos]="$char"
    local y=$((cY + yRad))
    local x=$((cX - xRad))
    local pos=$((y*COLUMNS + x))
    scr[$pos]="$char"
  done
}


echo "$COLUMNS cols, $LINES lines"



#printBuffer scr

frametimes=""
count=0;

exec 4>&1 #save stdout to enable bash profiling
clear
tput civis
trap "clear; tput cnorm" EXIT
trap "clear; tput cnorm; exit;" SIGINT SIGTERM

TIMEFORMAT="%3R";

#printBuffer scr

#read;

#clearTimeA=$(time ( stringClear; printStringBuffer ) 2>&1 1>&4)
#clearBuffer
#clearTimeB=$(time ( clearBuffer ) 2>&1 1>&4)
#printBuffer scr
#read
#echo "$clearTimeA  ; $clearTimeB"
#read
#exit
clear
for (( ;; )); do
  starttime=$(date +"%-N")

  #stringClear
  clearBuffer # TODO: check why this is necessary
  #clearTime=$(time ( clearBuffer ) 2>&1 1>&4)
  
  #for i in $(seq 0 $((COLUMNS * BUFFERLINES-1))); do
    #TODO: check how fast native temrinal sequences are
    #setTo 0 0 '0'
    #setTo 1 0 '0'
    #setTo 0 1 '1'
    #setTo $i 2 '0'
    #setToString 0 0 '0'
    #setToString 1 0 '0'
    #setToString 0 1 '1'
    #setToString $i 2 '0'
    #setTo $((i % COLUMNS)) $(( i / COLUMNS )) 'a'
  #done
  drawRect 0 0 3 3 "X" 
  fillRect 4 4 8 8 "O"
  drawLine 10  0 25  0 " "
  drawLine 10  2 25  3 " "
  drawLine 10  4 25  6 " "
  drawLine 10  6 25  9 " "
  drawLine 10  8 25 12 " "
  drawLine 10 10 25 15 " "
  drawLine 10 12 25 18 " "
  drawLine 10 14 25 21 " "
  drawLine 10 16 25 24 " "
  drawLine 10 18 25 27 " "
  drawLine 10 20 25 30 " "
  drawLine 10 22 25 33 " "
  drawLine 10 24 25 36 " "
  drawLine 10 26 25 39 " "
  drawLine 10 28 25 42 " "
  drawLine 10 30 25 45 " "

  drawLine 55 20 30 10 " "
  drawLine 30  8 55  2 " "

  drawLine 60  5 65 45 " "
  
  drawLine 70  5 70 45 " "
  drawLine 72 45 72  5 " "
  drawLine 75 45 79  5 " "
  drawLine 85 45 80  5 " "
  drawLine 90  5 86 45 " "

  for i in {1..6}; do
    drawCircle 25 25 $(( 20 - 3*i)) "$i"
  done
  drawCircle 40 40 5 'y'
  drawCircle 60 40 4 'k'
  drawCircle 60 20 2 'm'
  drawCircle 60 10 3 'o'

  #printf "$screenBuffer"
  bashtime=$(time ( printBuffer scr ) 2>&1 1>&4)
  #bashtime=$(time ( printStringBuffer ) 2>&1 1>&4)
  endtime=$(date +"%-N")

  difftime=$(( (endtime - starttime)/1000 ))
  tput cup 0 0
  echo "difftime = $difftime ; bashtime = $bashtime ; clearTime = $clearTime            "

  read

  if (( difftime > 0 && difftime < 16667 )); then
    sleeptime=$(( 16667 - difftime ))
    #sleepfraction=$(printf "0.0%.5i" $sleeptime)
    #sleep "$sleepfraction"

    endtime=$(date +"%-N")
    difftime=$(( (endtime - starttime)/1000 ))
  fi

  if (( difftime >= 0 )); then
    frametimes="$frametimes\n$difftime"
  fi
  let count++
  if (( count > 300)); then
    break
  fi
done

echo -n "number frame time lines "
echo -e "$frametimes" | wc -l
read 
echo -e "$frametimes" | less

reset
clear


