# Kai Chen
# For GBTX testing
# example to use the HDLC library, on FELIX
# Under GPL v3.0 license.

import os
import sys
from HDLC_ICEC_LIB_CK import IC_PACKING
from HDLC_ICEC_LIB_CK import IC_DEPACKING

REG_ICEC_CHANSEL=0x58c0
REG_TX_ICDATA_63to0=0x5900
REG_TX_ICDATA_127to64=0x5910
REG_TX_ICDATA_191to128=0x5920
REG_TX_ICDATA_255to192=0x5930
REG_ICEC_TRIG=0x58b0

REG_RX_ICDATA_63to0=0x6a00
REG_RX_ICDATA_127to64=0x6a10
REG_RX_ICDATA_191to128=0x6a20
REG_RX_ICDATA_255to192=0x6a30
REG_ICECBUSY =0x6a80

REG_FECERROR =0x6750
REG_BITERROR_RESET =0x5410

def reg_read64b(addr):
    addr_str=str(hex(addr))
    cmd="../../svn1029/hostSoftware/f/pepo/pepo -u 1 -k -o " + addr_str + " -r -n 64"
    retvalue = os.popen(cmd).readlines()
#    print(retvalue[0][0:18])
    ret="{0:016x}".format(int(retvalue[0][2:18],16))
    return ret

def reg_write64b(addr,data):
    addr_str=str(hex(addr))
    data_str=str(hex(data))
    os.system("../../svn1029/hostSoftware/f/pepo/pepo -u 1 -k -o " + addr_str + " -w "+ data_str + " -n 64")

GBTX_DATA=range(16)

if sys.argv[1]=="-h":
    print "Please use below format to read"
    print "ICOP.py -t 2 -s 0x02 -a 0x0034 -l 1 -r"
    print "Or use below format to write"
    print "ICOP.py -t 2 -s 0x02 -a 0x0034 -l 1 -w 0x3F"
    print "-t is tx GBT channel number, decimal: 0-23"
    print "script will check, which RX channel this link uses"
    print "if the link connection is wrong, script can know the connection"
    print "by reading 0x6a80"
    print "-s is GBTX device I2C address, hex"
    print "-a is the GBTx register address, hex"
    print "-l is how many bytes to read/write, decimal: 1-16"
    print "-r is read operation"
    print "-w is write operation, use hex data, length must match -l"
    print "the sequence is 0xABCDEF...AB is for address set by -a, "
    print "CD is for this address plus 1..."
if sys.argv[1]!="-t":
    print "please use '-h' to see help..."
    sys.exit()
else:
    channel=int(sys.argv[2])
    if channel <0 or channel >23:
        print "please use '-h' to see help..."


if sys.argv[3]!="-s":
    print "please use '-h' to see help..."
    sys.exit()
else:
    GBTX_I2CADDR=int(sys.argv[4],16)

if sys.argv[5]!="-a":
    print "please use '-h' to see help..."
    sys.exit()
else:
    GBTX_ADDR=int(sys.argv[6],16)

if sys.argv[7]!="-l":
    print "please use '-h' to see help..."
    sys.exit()
else:
    GBTX_LEN=int(sys.argv[8])
    if GBTX_LEN>16 or GBTX_LEN<1:
        print "please use '-h' to see help..."
        sys.exit()

if sys.argv[9]=="-r":
    GBTX_RW=1
    print "read operation..."

elif sys.argv[9]=="-w":
    GBTX_RW=0
    if sys.argv[10][1]=='x' or sys.argv[10][1]=='X':
        data_orig=sys.argv[10][2:]
        if len(sys.argv[10])!=2*GBTX_LEN+2:
            print "length doesn't match..."
            sys.exit()
        print "write operation..."
        for i in range(GBTX_LEN):
            GBTX_DATA[i]=int(data_orig[2*i:2*i+2],16)
    else:
        data_orig=sys.argv[10]
        if len(sys.argv[10]!=2*GBTX_LEN):
            print "length doesn't match..."
            sys.exit()
        print "write and read operation..."
        for i in range(GBTX_LEN):
            GBTX_DATA[i]=int(data_orig[2*i:2*i+2],16)
else:
    sys.exit()




[TXDATA0, TXDATA1, TXDATA2, TXDATA3]=IC_PACKING(GBTX_I2CADDR, GBTX_ADDR, GBTX_LEN, GBTX_RW, GBTX_DATA)

print "---------------Tx information------------------"
print "Check the Rx packet"
print "TX GBT CHANNEL: " + str(channel)
print "GBTX I2C ADDR: " + str(hex(GBTX_I2CADDR))
print "GBTX REG ADDR: " + str(hex(GBTX_ADDR))
print "GBTX BYTES R/W LENGTH, 1 means 1 byte: " + str(GBTX_LEN)
print "GBTX OPERATION TYPE, 1 means READ, 0 means WRITEandREAD: " + str(GBTX_RW)
if GBTX_RW==0:
    print "GBTX DATA TO SENT: " + str(GBTX_DATA[0:GBTX_LEN])
print "-------------Tx packet--------------------------"
print hex(TXDATA0)
print hex(TXDATA1)
print hex(TXDATA2)
print hex(TXDATA3)



reg_write64b(REG_ICEC_CHANSEL, channel*257)

reg_write64b(REG_TX_ICDATA_63to0, TXDATA0)
reg_write64b(REG_TX_ICDATA_127to64, TXDATA1)
reg_write64b(REG_TX_ICDATA_191to128, TXDATA2)
reg_write64b(REG_TX_ICDATA_255to192, TXDATA3)

reg_write64b(REG_ICEC_TRIG, 2**channel)
reg_write64b(REG_ICEC_TRIG, 0x0)
done=0
BUSY_SIGNAL=int(reg_read64b(REG_ICECBUSY),16)
reg_write64b(REG_BITERROR_RESET, 0x1)
reg_write64b(REG_BITERROR_RESET, 0x0)
FEC_ERROR=int(reg_read64b(REG_FECERROR),16)

if int(BUSY_SIGNAL/(2**(channel)))%2 ==0 and int(FEC_ERROR/(2**(channel)))%2 ==0:
    done=1
    rxchannel=channel
    print "the same RX GBT channel get replied message"
else:
    temp=BUSY_SIGNAL
    err_temp=FEC_ERROR

    for i in range(24):
        print i
        if temp%2==0 and err_temp%2==0 :
            rxchannel=i
            print "the RX GBT channel %d get replied message" % rxchannel
            done=1
            break;
        else:
            temp=int(temp/2)
            err_temp=int(err_temp/2)
if done==0:
    print "operation failed"


reg_write64b(REG_ICEC_CHANSEL, rxchannel*257)

RXDATA0=int(reg_read64b(REG_RX_ICDATA_63to0),16)
RXDATA1=int(reg_read64b(REG_RX_ICDATA_127to64),16)
RXDATA2=int(reg_read64b(REG_RX_ICDATA_191to128),16)
RXDATA3=int(reg_read64b(REG_RX_ICDATA_255to192),16)
'''
RXDATA0=TXDATA0
RXDATA1=TXDATA1
RXDATA2=TXDATA2
RXDATA3=TXDATA3
'''
print "-------------Rx packet--------------------------"
print hex(RXDATA0)
print hex(RXDATA1)
print hex(RXDATA2)
print hex(RXDATA3)


[GBTX_I2CADDR, GBTX_ADDR, GBTX_LEN, GBTX_RW, GBTX_DATA, TXCHK, RXCHK]=IC_DEPACKING(RXDATA0, RXDATA1, RXDATA2, RXDATA3)
print "-------------Check the Rx packet--------------------"
print "RX GBT CHANNEL: " + str(rxchannel)
print "GBTX DEVICE ADDR: " + str(hex(GBTX_I2CADDR))
print "GBTX REG ADDR: " + str(hex(GBTX_ADDR))
print "GBTX BYTES R/W LENGTH, 1 means 1 byte: " + str(GBTX_LEN)
print "GBTX OPERATION TYPE, 1 means READ, 0 means WRITEandREAD: " + str(GBTX_RW)
print "GBTX DATA READBACK: " + str(GBTX_DATA[0:GBTX_LEN])
if GBTX_RW==0:
    print "GBTX TX PARITY CHECK, 1 means no error: " + str(TXCHK)
print "GBTX RX PARITY CHECK, 1 means no error: " + str(RXCHK)
