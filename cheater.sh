#!/bin/bash

# https://github.com/Linux-RISC/Sungrow-Meter-cheater

# https://stackoverflow.com/questions/2746553/read-values-into-a-shell-variable-from-a-pipe
shopt -s lastpipe

#--------------------------------------------------------------------------------
function Shelly_get_em0 () {

./Shelly_get_em0.sh | read power

# debugging
#echo $power

command='LC_NUMERIC=C printf "%.0f" $power'
power=$(eval $command)

# debugging
#echo "power="$power

if (( $power<0 )); then
   (( C2_power=4294967296+power ))
else
   (( C2_power=power ))
fi

}
#--------------------------------------------------------------------------------

sleep 10
device="/dev/ttyUSB0"
stty -F $device 9600 -parenb -parodd -cmspar cs8 -hupcl -cstopb cread clocal -crtscts -ignbrk -brkint -ignpar -parmrk -inpck -istrip -inlcr -igncr -icrnl -ixon -ixoff -iuclc -ixany -imaxbel -iutf8 -opost -olcuc -ocrnl onlcr -onocr -onlret -ofill -ofdel nl0 cr0 tab0 bs0 vt0 ff0 -isig -icanon -iexten -echo echoe echok -echonl -noflsh -xcase -tostop -echoprt echoctl echoke -flusho -extproc

# https://github.com/Linux-RISC/Sungrow-Meter-cheater/issues/1 --> octera -->
# https://github.com/bohdan-s/Sungrow-Inverter/blob/main/Modbus%20Information/DTSU666%20Meter%20Communication%20Protocol_20210601.pdf

# DTSU666: address 0xFE, device type coding 0x20D5
# Read Holding Registers: slave 254 ($FE), register 63 ($3F), 1 register, address
R63_1_3FH="fe03003f0001a009"
# Read Holding Registers: slave 254 ($FE), register 356 ($0164), 8 registers, Active power of phase A,B,C and Total active power
R356_8_0164H="fe03016400081020"
# Read Holding Registers: slave 254 ($FE), register 10 ($0A), 12 registers, Current forward active total/spike/peak/flat/valley/... electric energy
R10_12_0AH="fe03000a000c71c2"
# Read Holding Registers: slave 254 ($FE), register 97 ($61), 3 registers, Voltage of A, B, C phase
R97_3_61H="fe0300610003401a"
# Read Holding Registers: slave 254 ($FE), register 119 ($77), 1 register, Frequency
R119_1_77H="fe0300770001201f"
# Read Holding Registers: slave 254 ($FE), register 20480 ($5000), 1 register
R20480_1_5000H="fe03500000018105"
# unknown request #1: slave 32 ($20)
unknown_1="207300000001c370"
# Read Holding Registers: slave 32 ($20), register 0 ($00), 13 registers
R0_13_00H="20030000000d82be"

while true
do

  request=$(xxd -l 8 -p $device)
  case $request in
    $R63_1_3FH)
      answer="FE0302FE01"
      ./calc_crc16.sh $answer | read CRC
      answer=$answer$CRC
      message="request: $request: slave 254 (\$FE), register 63 (\$3F), 1 register | answer: address=254 (\$FE), baud rate=1 (9600 bps) $answer"
      echo $message
      echo "$answer" | xxd -r -p > $device
      ;;

    $R356_8_0164H)
# https://www.exploringbinary.com/twos-complement-converter/
# two's complement
# 2#00000000000000000000000000000000=16#0000 0000=0
# 2#00000000000000000000000000000001=16#0000 0001=1
# ...
# 2#01111111111111111111111111111111=16#7FFF FFFF=2147483647
# 2#10000000000000000000000000000000=16#8000 0000=2147483648=-2147483648 (C2)
# 2#10000000000000000000000000000001=16#8000 0001=2147483649=-2147483647 (C2)
# 2#10000000000000000000000000000010=16#8000 0002=2147483650=-2147483646 (C2)
# ...
# 2#11111111111111111111111111111111=16#FFFF FFFF=4294967295=-1 (C2)
      # R356 HW+R357 LW=Active power of A phase W (C2)
      # R358 HW+R359 LW=Active power of B phase W (C2)
      # R360 HW+R361 LW=Active power of C phase W (C2)
      # R362 HW+R363 LW=Total active power W (C2)
#      echo "answering to $request"
#      answer="FE0310000000640000000000000000000000644E96"
#      echo "$answer" | xxd -r -p > $device
#continue

      Shelly_get_em0

      # debugging
      #echo "power="$power
      #echo "C2_power="$C2_power

      hex=$(printf "%04X" $C2_power)

      # debugging
      #echo "hex="$hex
      if (( power<0 )); then
         # 8 registers * 4 = 32 chars
         # length($hex)=8 --> 16 zeroes+2x $hex
	 # 16 zeroes = 4 registers
         answer="FE0310"$hex"0000000000000000"$hex
      else
         # 8 registers * 4 = 32 chars
         # length($hex)=4 --> 24 zeroes+2x $hex
         # 4+20 zeroes = 6 registers
         answer="FE03100000"$hex"00000000000000000000"$hex
      fi
      ./calc_crc16.sh $answer | read CRC
      answer=$answer$CRC

      echo "request: $request: slave 254 (\$FE),register 356 (\$0164), 8 registers, Active power of phases A,B,C and Total active power | answer: (A,Total="$power" W, B,C=0 W) $answer"
      echo "$answer" | xxd -r -p > $device
      ;;

    $R10_12_0AH)
      answer="FE03180000000000000000000000000000000000000000000000006F1F"
      echo "request: $request, register 10 (\$0A), 12 registers, Current forward active total/spike/peak/flat/valley/... electric energy | answer: (0,0,0,0,0,0) $answer"
      echo "$answer" | xxd -r -p > $device
      ;;

    $R97_3_61H)
      answer="FE030600E600000000"
      ./calc_crc16.sh $answer | read CRC
      answer=$answer$CRC
      echo "request: $request: slave 254 (\$FE), register 97 (\$61), 3 registers, Voltage of A, B, C phase | answer: (230 V,0,0) $answer"
      echo "$answer" | xxd -r -p > $device
      ;;

    $R119_1_77H)
      answer="FE03020032"
      ./calc_crc16.sh $answer | read CRC
      answer=$answer$CRC
      echo "request: $request: slave 254 (\$FE), register 119 (\$77), 1 register, Frequency | answer: 50 Hz, $answer"
      echo "$answer" | xxd -r -p > $device
      ;;

    $R20480_1_5000H)
      answer="FE030220D5"
      ./calc_crc16.sh $answer | read CRC
      answer=$answer$CRC
      echo "request: $request: slave 254 (\$FE), register 20480 (\$5000), 1 register | answer: device type coding=0x20D5 $answer"
      echo "$answer" | xxd -r -p > $device
      ;;
    $unknown_1)
      answer=$unknown_1
      #./calc_crc16.sh $answer | read CRC
      #answer=$answer$CRC
      echo "request: $request: slave \$20, register 0 (\$00), 1 register | answer: $answer"
      echo "$answer" | xxd -r -p > $device
      ;;
    $R0_13_00H)
      # the inverter get stuck requesting this request if this answer is used
      #answer="20031A0000000000000000000000000000000000000000000000000000"
      answer="20031A000000010000000100000001000000010000000100000001000"

      ./calc_crc16.sh $answer | read CRC
      answer=$answer$CRC
      echo "request: $request: slave 32 (\$20), register 0 (\$00), 13 registers | answer: $answer"
      echo "$answer" | xxd -r -p > $device
      ;;
    *)
      echo "unknown request $request"
      ;;
  esac
done
