- Note: 
  + The Endian for the 2 IC bits and EC bits are different.
  + 2 bits of EC Tx are swapped in the wrapper.vhd. 
  + 2 bits of EC Rx may be not swapped, due to some reason from GBTX (or maybe GBT-SCA).
  	 * So muxsel is used to support the Endian change for these 2 EC Rx bits.