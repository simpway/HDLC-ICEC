- Note: 
  + The Endian for the 2 IC bits and EC bits are different.
  + 2 bits of EC Tx are swapped in the wrapper.vhd. 
  + 2 bits of EC Rx may be not swapped, due to some reason from GBTX (since when the GBTx convert 80M x1 bit to 40M x2 bit, there are two possible phases). We check the 0x7E at 255-248, or 254-247, to solve this problem.
  	 * Muxsel is used to support the Endian change for these 2 EC Rx bits. But it should be 0 when using it.