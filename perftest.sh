#! /bin/bash

COLUMNS=$(tput cols)
LINES=$(tput lines)

dbg00=$(tput cup 0 0)
dbg01=$(tput cup 0 $((COLUMNS/2)) )
dbg10=$(tput cup 1 0)
dbg11=$(tput cup 1 $((COLUMNS/2)) )
dbg20=$(tput cup 2 0)
dbg21=$(tput cup 2 $((COLUMNS/2)) )

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
for column in $(seq 1 $COLUMNS); do
  aColumn="${aColumn} ."
done

function stringClear {
  screen=""
  #for line in $(seq 0 $((LINES-1))); do
  #aColumn=$aColumn"\n"
  #done
  for line in $(seq 1 $BUFFERLINES); do
    #screen=$screen"$aColumn"
    screen="${screen}${aColumn}"
  done

  echo "rows $BUFFERLINES cols $COLUMNS screen length = ${#screen} , combined = $((BUFFERLINES * COLUMNS * 2))"
  read
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

bufStart=$(tput cup $frameLines 0)
function printBuffer {
  local -n buffer=$1
  printf "$bufStart"
  printf "%s" "${buffer[@]}"
}
allindices=$(seq 0 $((BUFFERLINES*COLUMNS-1)))
function clearBuffer {
  IFS="."; read -a scr <<< "$screen"; IFS="$defaultIFS"

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
    local py1=$((y_1*COLUMNS+c))
    scr[$py1]=$char
    local py2=$((y_2*COLUMNS+c))
    scr[$py2]=$char
  done

  for (( r = y_1; r < y_2; ++r )); do
    local px1=$((r*COLUMNS+x_1))
    scr[$px1]=$char
    local px2=$((r*COLUMNS+x_2))
    scr[$px2]=$char
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
      scr[$((l*COLUMNS+c))]=$char
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
        #scr[$pos]="$ind"
        scr[$pos]="$char"
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
        scr[$pos]="$char" #"$ind"
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
        scr[$pos]="$char" #$ind"
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
        scr[$pos]="$char" #$ind"
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


function setUpRot {
  local cX=0
  local cY=0
  local rad=100
  local xR=1
  local yR=1

  local xRad=0
  local yRad=$rad
  maxRotDistance=0

  while (( $yRad != 0 )) ; do
    local cRef=$(( (xR*rad)**2 ))

    right=$(( (xRad*yR+yR)**2 + (yRad*xR)**2 )) 
    down=$(( (xRad*yR)**2 + (yRad*xR-xR)**2 )) 
    rightdown=$(( (xRad*yR+yR)**2 + (yRad*xR-xR)**2 )) 

    ((right = (right - cRef)**2 ))
    ((down = (down - cRef)**2 ))
    ((rightdown = (rightdown - cRef)**2 ))

    if (( right <= down && right <= rightdown )); then
      (( maxRotDistance+=100 ))
      (( xRad++ ))
    elif (( down <= right && down <= rightdown )); then
      (( maxRotDistance+=100 ))
      (( yRad-- ))
    else
      (( maxRotDistance+=141 ))
      (( xRad++ ))
      (( yRad-- ))
    fi
  done
}

function getVecForRot { #  deg
  local cX=0
  local cY=0
  local rad=100
  local xR=1
  local yR=1
  local degrees=$1
  (( degrees = (degrees + 360) % 360 ))

  # Idea:
  # x^2 + y^2 = M
  # check right, down, right-down.
  # goto and set field with value closest to M

  xRad=0
  yRad=$rad

  # distance / 90 grad    ->  distance / 90 / 45 --> distance * r / 90 

  distanceToTravel=$((maxRotDistance * (degrees % 90) / 90 ))
  distance=0

  while (( distance < distanceToTravel && yRad != 0 )) ; do
    local cRef=$(( (xR*rad)**2 ))

    right=$(( (xRad*yR+yR)**2 + (yRad*xR)**2 )) 
    down=$(( (xRad*yR)**2 + (yRad*xR-xR)**2 )) 
    rightdown=$(( (xRad*yR+yR)**2 + (yRad*xR-xR)**2 )) 

    ((right = (right - cRef)**2 ))
    ((down = (down - cRef)**2 ))
    ((rightdown = (rightdown - cRef)**2 ))

    if (( right <= down && right <= rightdown )); then
      (( distance+=100 ))
      (( xRad++ ))
    elif (( down <= right && down <= rightdown )); then
      (( distance+=100 ))
      (( yRad-- ))
    else
      (( distance+=141 ))
      (( xRad++ ))
      (( yRad-- ))
    fi
  done

  if (( degrees < 90 )); then
    outRadX=$((-xRad))
    outRadY=$((-yRad))
  elif (( degrees < 180 )); then
    outRadX=$((-yRad))
    outRadY=$((xRad))
  elif (( degrees < 270 )); then
    outRadX=$((xRad))
    outRadY=$((yRad))
  else
    outRadX=$((yRad))
    outRadY=$((-xRad))
  fi
}

function drawCircleR { # cX cY rad xR yR char
  local cX=$1
  local cY=$2
  local rad=$3
  local xR=$4
  local yR=$5
  local char=$6

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

  while (( $yRad != 0 )) ; do
    # TODO: cRef isn't correct yet
    local cRef=$(( (xR*rad)**2 ))

    right=$(( (xRad*yR+yR)**2 + (yRad*xR)**2 )) 
    down=$(( (xRad*yR)**2 + (yRad*xR-xR)**2 )) 
    rightdown=$(( (xRad*yR+yR)**2 + (yRad*xR-xR)**2 )) 

    echo -n "$dbg20" "xR $xR yR $yR | xRad $xRad | yRad $yRad | r $right d $down rd $rightdown | ref $cRef             "

    ((right = (right - cRef)**2 ))
    ((down = (down - cRef)**2 ))
    ((rightdown = (rightdown - cRef)**2 ))

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

function scaleToLength { #x #y #length
  local x=$1
  local y=$2
  local length=$3

  local flipX=$(( x < 0 ))
  local flipY=$(( y < 0 ))

  local x=$(( x > 0 ? x : -x ))
  local y=$(( y > 0 ? y : -y ))

# Step 1 : calculate projection to [0 100] [100 0] line
  if (( y > 0 && x > y)); then
    # normalize by x
    xl=$(( 100*x / (x+y) ))
    yl=$(( 100-xl))
  else
    #normalize by y
    yl=$(( 100*y / (x+y) ))
    xl=$(( 100-yl ))
  fi

  # Step 2 : calculate projection to [0 140] [140 0] line
  if ((x > y)); then
    # normalize by x
    xMax=$(( 140*x / (x+y) ))
    yMax=$(( 140-xMax))
  else
    #normalize by y
    yMax=$(( 140*y / (x+y) ))
    xMax=$(( 140-yMax ))
  fi

  # Step 3 : Calculate line length of Step 1

  absDiff=$(( (xl - yl) >= 0 ? xl - yl : yl - xl ))

  # Step 4 : Combine Step 1, Step 3

  ## mdist =  (2 + 1 - abs(xl-yl) / scale) / 2
  ## approxX = xl.*mdist
  ## approxY = yl.*mdist

  #                  (200+100 - abs(xl-yl)           300 - abs(xl-yl)
  # approxX = xl *   -----------------------  = xl * ----------------
  #                  scale * 2                        scale * 2

  x_a=$(( xl * (300 - absDiff) / 200 ))
  y_a=$(( yl * (300 - absDiff) / 200 ))

  # Step 5 : Use min(step4, step 2) as the result
  x_=$(( x_a < xMax ? x_a : xMax ))
  y_=$(( y_a < yMax ? y_a : yMax ))

  if (( flipX )); then x_=$(( -x_ )); fi
  if (( flipY )); then y_=$(( -y_ )); fi
}

echo "$COLUMNS cols, $LINES lines"



#printBuffer scr

frametimes=""
count=0;

exec 4>&1 #save stdout to enable bash profiling
clear
tput civis
trap "clear; tput cnorm; stty echo; " EXIT
trap "clear; tput cnorm; stty echo; exit;" SIGINT SIGTERM

TIMEFORMAT="%3R";


function playground {
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
    echo "$dbg00 difftime = $difftime ; bashtime = $bashtime ; clearTime = $clearTime            "

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
}

# units: cm (100 == 1 m)
# map block size = 100
#
# BLOCK on screen
# 
#    123456789                     
#                  
#    XXXXXXXXX 1
#    XXXXXXXXX 2
#    XXXXXXXXX 3
#    XXXXXXXXX 4
#
# scale = 4:9
#                         
# TODO:
# * implement smooth scroll
# DONE: 
# * display map (top left)
# * implement map zoom
# * implement scroll

origScaleX=$((9))
origScaleY=$((4))

playerPosX=$((8*100+50))
playerPosY=$((4*100+50))
playerVX=$((10))
playerVY=$((7))
camPosX=$((1600))
camPosY=$((1600))

mapWidth=$((32))
mapHeight=$((22))
 map="1#2#3#4#6#7#8#9#a#b#c#d#e#f#g#h#" # 1
map+="l..#.......#...................r" # 2
map+="l..#.......#.#.#.##.#..#...#...r" # 3
map+="l..#########.#.#.#..#..#..#.#..r" # 4
map+="l5.....#.#.#.###.##.#..#..#.#..r" # 5
map+="l......#####.#.#.#..#..#..#.#..r" # 6
map+="l..#.........#.#.##.##.##..#...r" # 7
map+="l..............................r" # 8
map+="l.##.......#...#..#..##..#..##.r" # 9
map+="l10........#...#.#.#.#.#.#..#.#r" # 10
map+="l..........#.#.#.#.#.##..#..#.#r" # 11
map+="l...........#.#..#.#.#.#.#..#.#r" # 12
map+="l...........#.#...#..#.#.##.##.r" # 13
map+="l..............................r" # 14
map+="l15............................r" # 15
map+="l..............................r" # 16
map+="l..............................r" # 17
map+="l..............................r" # 18
map+="l..............................r" # 19
map+="l20............................r" # 20
map+="l..............................r" # 21
map+="################################" # 22

#source perf.map
source simplemap.map

# create array from string map
IFS=" "; read -a mapArr <<< $(echo "$map" | sed 's/\(.\)/\1 /g'); IFS="$defaultIFS"
# verify integrity
[ ${#map} != $((mapWidth * mapHeight)) ] && echo "MapSizeMismatch" 

follow=$((0))
snapToGrid=$((1))
debug=$((0))
scX=$((origScaleX))
scY=$((origScaleY))

function recalcSettings {
  visibleTilesX=$((COLUMNS / scX))
  visibleTilesX=$((visibleTilesX >= mapWidth ? mapWidth : visibleTilesX)) # clamp
  visibleTilesY=$((BUFFERLINES / scY))
  visibleTilesY=$((visibleTilesY >= mapHeight ? mapHeight : visibleTilesY)) #clamp

  visibleSubTilesX=$((COLUMNS % scX))
  visibleSubTilesX=$((visibleTilesX >= mapWidth ? 0 : visibleSubTilesX)) # clamp
}

function resetScale {
  scX=$((origScaleX))
  scY=$((origScaleY))
  recalcSettings
}

function incScale {
  origRat=$((origScaleX * 100 / origScaleY))
  scY=$((scY+1))
  rat=$((scX*100/scY)) 
  newRat=$(((scX+1)*100/scY))
  while (( (origRat-newRat)**2 < (origRat-rat)**2 )); do
    scX=$((scX+1))
    rat=$((scX*100/scY)) 
    newRat=$(((scX+1)*100/scY))
  done
  recalcSettings
}
function decScale {
  (( scX <= 1 || scY <= 1 )) && return

  origRat=$((origScaleX * 100 / origScaleY))
  scY=$((scY-1))
  rat=$((scX*100/scY)) 
  newRat=$(((scX-1)*100/scY))
  while (( (origRat-newRat)**2 < (origRat-rat)**2 )); do
    scX=$((scX-1))
    ((scX == 1)) && break
    rat=$((scX*100/scY)) 
    newRat=$(((scX-1)*100/scY))
  done

  recalcSettings
}

recalcSettings

camPosX=$((visibleTilesX/2*100+1))
camPosY=$((visibleTilesY/2*100+1))
setUpRot

rot=0

stty -echo
lastTime=$(date +"%-s%N")

while [ 1 ]; do
  clearBuffer

  mapSizePxWidth=$((mapWidth*scX))
  mapSizePxHeight=$((mapHeight*scY))

  w2camX=$((camPosX-(COLUMNS)*100/scX/2))
  w2camY=$((camPosY-(BUFFERLINES)*100/scY/2))

  curTime=$(date +"%-s%N")
  elapsedTime=$(( (curTime - lastTime) / 1000000))
  lastTime=$((curTime))
  printf "${dbg00}Frametime $elapsedTime ms                 "

  if (( follow == 1)); then
    camPosX=$((playerPosX))
    camPosY=$((playerPosY))
  fi

  camWorldX=$((camPosX / 100))
  camWorldY=$((camPosY / 100))

  if (( snapToGrid == 1)); then
    camSubTilePosX=$(( (camPosX % 100)*scX/100 ))
    camSubTilePosY=$(( (camPosY % 100)*scY/100 ))
  fi

  echo -n "$dbg11 subX = $camSubTilePosX | subY = $camSubTilePosY"

  camPxX=$((camPosX*scX/100))
  camPxY=$((camPosY*scY/100))


  startX=$((0-camPxX+COLUMNS/2))
  startY=$((0-camPxY+BUFFERLINES/2))
  endX=$((0+mapSizePxWidth-camPxX+COLUMNS/2))
  endY=$((0+mapSizePxHeight-camPxY+BUFFERLINES/2))
  ((startX < 0)) && startX=$((0)); (( endX > COLUMNS )) && endX=$((COLUMNS))
  ((startY < 0)) && startY=$((0)); (( endY > BUFFERLINES )) && endY=$((BUFFERLINES))

  echo -n "$dbg01 screensize $COLUMNS x $BUFFERLINES | cam $camPxX $camPxY | sX $startX sY $startY endX $endX endY $endY"

  for ((y = startY; y < endY; )); do

    tilePxY=$((camPxY-(BUFFERLINES)/2+y))
    tileWY=$((tilePxY/scY))
    rectHeight=$((y==0 ? scY-(tilePxY % scY) : scY))
    rectHeight=$((y+rectHeight >= BUFFERLINES ? BUFFERLINES-y : rectHeight ))

    for ((x = startX; x < endX ; )); do

      tilePxX=$((camPxX-COLUMNS/2+x))
      tileWX=$((tilePxX/scX))
      rectWidth=$((x==0 ? scX-(tilePxX % scX) : scX))
      rectWidth=$((x+rectWidth >= COLUMNS ? COLUMNS-x-0 : rectWidth))

      mapChar="${mapArr[$((tileWY*mapWidth + tileWX))]}" 

      if [ "$mapChar" != "." ]; then
        fillRect $((x)) $((y)) $((x+rectWidth)) $((y+rectHeight)) "$mapChar"
      fi

      #if (( x != 0 && y!=0 )); then
      #  cX=$((tilePxX - (camPxX-COLUMNS/2) ))
      #  cY=$((tilePxY - (camPxY-BUFFERLINES/2) ))
      #  #setTo $cX $cY "S"
      #  cX=$((tilePxX+scX/2 - (camPxX-COLUMNS/2) ))
      #  cY=$((tilePxY+scY/2 - (camPxY-BUFFERLINES/2) ))
      #  #setTo $cX $cY "C"

      #  tileWorldX=tileWX*100
      #  tileWorldY=tileWY*100
      #  tileWX_pxX=tileWorldX*scX/100
      #  tileWY_pxY=tileWorldY*scY/100

      #  cX=$((tileWX_pxX - (camPxX-COLUMNS/2) ))
      #  cY=$((tileWY_pxY - (camPxY-BUFFERLINES/2) ))
      #  ((cX>=0 && cX<COLUMNS && cY>=0 && cY < BUFFERLINES)) && setTo $cX $cY "O" # tile origin

      #  cX=$((tileWX_pxX + scX/2 - (camPxX-COLUMNS/2) ))
      #  cY=$((tileWY_pxY + scY/2 - (camPxY-BUFFERLINES/2) ))
      #  ((cX>=0 && cX<COLUMNS && cY>=0 && cY < BUFFERLINES)) && setTo $cX $cY "C" # tile center
      #fi
      #setTo $x $y "O"

      if ((debug == 1)); then
        printBuffer scr
        echo -n "$dbg20 $x $y | campos x $camPosX y $camPosY | tilePxX $tilePxX tilePxY $tilePxY camPxX $camPxX camPxY $camPxY tileWX $tileWX tileWY $tileWY    "
        echo -n "$dbg10 starX=$startX startY=$startY endX=$endX endY=$endY          "
        read
      fi
      ((x+=rectWidth))
    done
    ((y+=rectHeight))
  done

  playerPxX=$(( playerPosX*scX/100 ))
  playerPxY=$(( playerPosY*scY/100 ))
  playerWX=$(( playerPxX - (camPxX-COLUMNS/2) ))
  playerWY=$(( playerPxY - (camPxY-BUFFERLINES/2) ))
  
  if ((playerWX >= 0 && playerWX <= COLUMNS && playerWY >= 0 && playerWY <= BUFFERLINES)); then
    setTo playerWX playerWY "p"

    radius=4
    if ((playerWX >= radius && playerWX <= (COLUMNS-radius) && playerWY >= radius && playerWY <= (BUFFERLINES-radius) )); then
      drawCircleR playerWX playerWY 5 9 4 "p"
    fi
  fi


  getVecForRot $rot
  spx0=$(( (camPosX + 0)*scX/100 ))
  spx1=$(( (camPosX + outRadX*3/6)*scX/100 ))
  spy0=$(( (camPosY + 0)*scY/100 ))
  spy1=$(( (camPosY + outRadY*3/6)*scY/100 ))
  echo -n "$dbg10 $spx0 $spx1 $spy0 $spy1 $maxRotDistance                               "
  (( rot+= 5 ))

  drawLine $(( spx0 - (camPxX-COLUMNS/2) )) $(( spy0 - (camPxY-BUFFERLINES/2) )) $(( spx1 - (camPxX-COLUMNS/2) )) $(( spy1 - (camPxY-BUFFERLINES/2) )) "g"

  #setTo $((COLUMNS/2)) $((BUFFERLINES/2)) "C"

  printBuffer scr

  for i in {1..2}; do
    read -t 0.010 -n 1 -s input
    case "$input" in
      i) ki=500 ;;
      j) kj=500 ;;
      k) kk=500 ;;
      l) kl=500 ;;
      f) ((follow^=1)) ;;
      g) ((snapToGrid^=1)) ;;
      +) incScale ;;
      -) decScale ;;
      r) resetScale ;;
      p) read ;;
      b) ((debug^=1)) ;;
    esac
  done

  echo -n "$dbg21 scX = $scX / scY = $scY             "

  # Player Movement Code
  oldX=$((playerPosX))
  oldY=$((playerPosY))

  ((playerPosX+=elapsedTime * playerVX / 200))
  ((playerPosY+=elapsedTime * playerVY / 200))

  pMapCharX=${mapArr[$(( oldY / 100 * mapWidth + playerPosX/100 ))]}
  pMapCharY=${mapArr[$(( playerPosY / 100 * mapWidth + oldX/100 ))]}
  #pMapCharX=${mapArr[$(( oldY/100 * mapWidth + playerPosX/100 ))]}
  #pMapCharY=${mapArr[$(( playerPosY/100 * mapWidth + oldX/100 ))]}

  if [ "$pMapCharX" != "." ]; then playerPosX=$oldX; ((playerVX*=-1)); fi
  if [ "$pMapCharY" != "." ]; then playerPosY=$oldY; ((playerVY*=-1)); fi

  # Keyboard Handling Code
  ((kj-=elapsedTime)); if ((kj > 0)); then ((camPosX-=1*elapsedTime/3)); fi
  ((kl-=elapsedTime)); if ((kl > 0)); then ((camPosX+=1*elapsedTime/3)); fi
  ((ki-=elapsedTime)); if ((ki > 0)); then ((camPosY-=1*elapsedTime/3)); fi
  ((kk-=elapsedTime)); if ((kk > 0)); then ((camPosY+=1*elapsedTime/3)); fi

  # Camera Position Code
#  ((camPosX <= 0)) && camPosX=$((0))
#  ((camPosX > mapWidth * 100-1)) && camPosX=$((mapWidth*100-1))
#  ((camPosY <= 0)) && camPosY=$((0))
#  ((camPosY > mapHeight * 100-1)) && camPosY=$((mapHeight*100-1))

done

stty echo
