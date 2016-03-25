
- The kernel is the HDLC_ICEC_LIB.py

- IC for GBTX example:
  + read 3 registers:   ICOP.py -t 0 -s 0x01 -a 0x0032 -l 3 -r
  + write 3 registers:  ICOP.py -t 0 -s 0x01 -a 0x0032 -l 3 -w 0x070038
  + -t tx link number
  + -s I2C addr

- EC for GBT-SCA example:
  + GBT-SCA: GPIO example
    * ECOP.py 0 0
    * ECOP1.py 1 0
    * ECOP2.py 2 0
  + 0 1 2 is the command number, ideally it should be +1 each time. The ctrl number will +2 inside. But actually when we don’t plus 1 here, the return frame will has 3 0x7E, we can process from the second one.
  + For real use, Tr. ID should also plus one, the top level software should check the RX Tr. ID with TX Tr. ID, sometimes command need to be resent, due to the GBT-SCA’s response.
  + When RX data has CRC error due to the hardware reason, command should also be resent.
  + The second 0 is the mux selection, if the 2 EC Rx bits (GBT-SCA return data via GBTx) are swaped (CRC error always happens, or/and delimiter number is 1), then try 1.
