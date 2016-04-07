[![DOI](https://zenodo.org/badge/21279/simpway/HDLC-ICEC.svg)](https://zenodo.org/badge/latestdoi/21279/simpway/HDLC-ICEC)
# HDLC-ICEC
Under GPL v3.0 license. 

This package is the python library for the IC control to GBTx, and EC control to GBT-SCA device.  
The kernel file is the HDLC\_ICEC\_LIB\_CK.py. This python library will do: HDLC bit stuffing/bit destuffing, parity generator/checking for IC, CRC generator/checing for EC. Files in firmware and software directory are examples with FELIX as back-end platform.

The design purpose:  
- For Back-End to Front-End path:  
  1. To generate a 256 bit HDLC format packet for the firmware.  
  2. Firmware simply shift the 256 bits to the 2 IC/EC bits. Other time these two bits are "11".  
- For Front-End to Back-End path:  
  1. Firmware simply shift the 2 IC/EC bits to the 256 bits register, when 0x7E is found, latch the register.   
  2. To decode the received 256 bit HDLC format packet from firmware, get the information.    
- According to you requirement, 256 bits register can be changed to bigger. You can also transfer the data to firmware byte by byte with a FIFO.  
- The example is based on FELIX. When without FELIX platform, VIO in chipscope can be used to exchange data between the software and firmware.  
- This package has been fully verified on VLDB and LTDB testing, for both of IC and EC configuration.
 
Kai Chen <kchen@bnl.gov>

