#!/bin/bash

# Calculate MODBUS RTU CRC-16

# References:
# https://ctlsys.com/support/how_to_compute_the_modbus_rtu_message_crc/
# https://github.com/onslauth/bash_crc16
# https://stackoverflow.com/questions/8564267/crc16-algorithm-from-c-to-bash
# https://crccalc.com/

function calc_crc16() {

  crc=0xFFFF

  #echo $1
  for ((x=0; x<${#1}; x+=2)) do

    char=${1:$x:2}
    #echo "char="$char
    byte=0x$char
    # simplified version
    #byte=0x${1:$x:2}
    #echo "byte="$byte

    # XOR byte into least sig. byte of crc
    crc=$(( crc^byte ))

    # Loop over each bit
    for ((b=1; b<=8; b++)); do

      # If the LSB is set, shift right and XOR 0xA001
      if (( (crc & 0x0001) != 0 )); then
         crc=$(( crc >> 1 ))
         crc=$(( crc^0xA001 ))
      # Else LSB is not set, just shift right
      else
         crc=$(( crc >> 1 ))
      fi

    done
  done

  # Note, this number has low and high bytes swapped, so use it accordingly (or swap bytes)
  #printf "CRC16=0x%X\n" $crc
  #printf "%X" $crc
  hex=$(printf "%04X" $crc)
  H_byte=${hex:2:2}
  L_byte=${hex:0:2}
  echo $H_byte$L_byte
}

#calc_crc16 123456789
#calc_crc16 1103006B0003
#calc_crc16 AABBCCDDEEFF
calc_crc16 $1
