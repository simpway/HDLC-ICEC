# Kai Chen
# For GBT-SCA testing
# example to use the HDLC library, on FELIX
# Under GPL v3.0 license.

from HDLC_ICEC_LIB_CK import EC_PACKING
from HDLC_ICEC_LIB_CK import EC_DEPACKING

import time, sys

def reg_read64b(addr):
    addr_str=str(hex(addr))
    cmd="../../svn1029/hostSoftware/f/pepo/pepo -u 1 -k -o " + addr_str + " -r -n 64"
    retvalue = os.popen(cmd).readlines()
    print(retvalue[0][0:18])
    ret="{0:016x}".format(int(retvalue[0][2:18],16))
    return ret

def reg_write64b(addr,data):
    addr_str=str(hex(addr))
    data_str=str(hex(data))
    os.system("../../svn1029/hostSoftware/f/pepo/pepo -u 1 -k -o " + addr_str + " -w "+ data_str + " -n 64")


REG_ICEC_CHANSEL=0x58c0
REG_TX_ECDATA_63to0=0x5940
REG_TX_ECDATA_127to64=0x5950
REG_TX_ECDATA_191to128=0x5960
REG_TX_ECDATA_255to192=0x5970
REG_ICEC_TRIG=0x58b0

REG_RX_ECDATA_63to0=0x6a40
REG_RX_ECDATA_127to64=0x6a50
REG_RX_ECDATA_191to128=0x6a60
REG_RX_ECDATA_255to192=0x6a70
REG_ICECBUSY =0x6a80

REG_FECERROR =0x6750
REG_BITERROR_RESET =0x5410
# will definie some common commands: e.g. enable which interface...
#GPIO test
# enable GPIO       : 00 N+0 78 00 01 02 00 04 plen= 8
# set dir OUTPUT    : 00 N+2 78 02 04 20 FF FF FF FF # 23-16 31-24 7-0 15-8  plen=10
# set output DATA   : 00 N+4 78 02 04 10 FF FF FF FF # 23-16 31-24 7-0 15-8
# GPIO 5/6
# set output DATA   : 00 N+6 78 02 04 10 DB FF FF FF # 23-16 31-24 7-0 15-8
# set output DATA   : 00 N+8 78 02 04 10 FF FF FF FF # 23-16 31-24 7-0 15-8

muxsel=int(sys.argv[2])

plen=8
DATA=range(10)
DATA[0]=0x00 #ADDR
DATA[1]=2*int(sys.argv[1])#0x0a #CTRL
DATA[2]=0x78 #Tr.ID
DATA[3]=0x00 #Channel
DATA[4]=0x01 #LEN
DATA[5]=0x02 #CMD
DATA[6]=0x00 #MSB DATA
DATA[7]=0x04 #LSB DATA
DATA[8]=0xFF #MSB DATA
DATA[9]=0xFF #LSB DATA
'''
plen=10
DATA=range(10)
DATA[0]=0x00 #ADDR
DATA[1]=0x02 #CTRL
DATA[2]=0x78 #Tr.ID
DATA[3]=0x02 #Channel
DATA[4]=0x04 #LEN
DATA[5]=0x10 #CMD
DATA[6]=0xFF #MSB DATA
DATA[7]=0xFF #LSB DATA
DATA[8]=0xFF #MSB DATA
DATA[9]=0xFF #LSB DATA
'''
[TXDATA0, TXDATA1, TXDATA2, TXDATA3]=EC_PACKING(DATA[0:plen])
print hex(TXDATA0)
print hex(TXDATA1)
print hex(TXDATA2)
print hex(TXDATA3)

rxchannel=0


channel=0
reg_write64b(REG_ICEC_CHANSEL, channel*257+muxsel*2**(32+rxchannel))

#time.sleep(30)

reg_write64b(REG_TX_ECDATA_63to0, TXDATA0)
reg_write64b(REG_TX_ECDATA_127to64, TXDATA1)
reg_write64b(REG_TX_ECDATA_191to128, TXDATA2)
reg_write64b(REG_TX_ECDATA_255to192, TXDATA3)

reg_write64b(REG_ICEC_TRIG, 2**(32+channel))
reg_write64b(REG_ICEC_TRIG, 0x0)

BUSY_SIGNAL=int(reg_read64b(REG_ICECBUSY),16)
rxchannel=0

time.sleep(0.5)
reg_write64b(REG_ICEC_CHANSEL, rxchannel*257+muxsel*2**(32+rxchannel))
RXDATA0=int(reg_read64b(REG_RX_ECDATA_63to0),16)
RXDATA1=int(reg_read64b(REG_RX_ECDATA_127to64),16)
RXDATA2=int(reg_read64b(REG_RX_ECDATA_191to128),16)
RXDATA3=int(reg_read64b(REG_RX_ECDATA_255to192),16)
'''
RXDATA0=TXDATA0
RXDATA1=TXDATA1
RXDATA2=TXDATA2
RXDATA3=TXDATA3
'''
print hex(RXDATA0)
print hex(RXDATA1)
print hex(RXDATA2)
print hex(RXDATA3)
[RXDATA, CRC_ERR_FLAG]=EC_DEPACKING(RXDATA0,RXDATA1,RXDATA2,RXDATA3)
if CRC_ERR_FLAG==0:
    print("No CRC error exist for GBT-SCA to Back-End")
else:
    print("Error happens for GBT-SCA to Back-End")

RXADDR=RXDATA[0]
RXCTRL=RXDATA[1]
RXTRID=RXDATA[2]
RXCHANNEL=RXDATA[3]
RXLEN=RXDATA[4]
RXERRFLAG=RXDATA[5]
RXDATAS=RXDATA[6:]


