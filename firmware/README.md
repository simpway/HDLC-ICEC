- Note: 
  + The Endian for the 2 IC bits and EC bits are different.
  + EC are swapped in the wrapper.vhd. But EC Rx may be not swapped, due to the phase uncertainty, between GBT-SCA and GBTX.
  + So muxsel is used.