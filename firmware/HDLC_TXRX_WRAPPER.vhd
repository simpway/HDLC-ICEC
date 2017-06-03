--!-----------------------------------------------------------------------------
--!                                                                           --
--!           BNL - Brookhaven National Lboratory                             --
--!                       Physics Department                                  --
--!                         Omega Group                                       --
--!-----------------------------------------------------------------------------
--|
--! author:      Kai Chen    (kchen@bnl.gov)
--!
--!
--!-----------------------------------------------------------------------------
--
-- Create Date:    21:33:01 2015/11/18
-- Design Name:
-- Module Name:    HDLC_TXRX - Behavioral
-- Project Name:
-- Target Devices:
-- Tool versions:
-- Description:   The MODULE to send data to IC/EC bit, and receive data from
--                IC/EC bit. The data encoding and decoding to/from HDLC shold
--                be done in software. This module only send and receive data
--                to a multi-bytes register. users can change its width.
--
-- Dependencies:
--
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
--
----------------------------------------------------------------------------------

LIBRARY IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
USE IEEE.STD_LOGIC_UNSIGNED.ALL;

library UNISIM;
use UNISIM.VComponents.all;

use work.pcie_package.all;
use work.FELIX_gbt_package.all;


entity HDLC_TXRX_WRAPPER is
  generic (
    REG_WIDTH           : integer := 256;
    GBT_NUM             : integer   := 24
    );
  port (
    
    txclk_40m           : in std_logic;
    rxclk_40m           : in std_logic;
    ICECBUSY            : out std_logic_vector(15 downto 0);
    ICEC_INT_RX_DATA    : out txrx64b_24ch_type;
    register_map_control: in    register_map_control_type;
    ICEC_RX_4b          : in txrx4b_type;
    ICEC_TX_4b          : out txrx4b_type

    );
end HDLC_TXRX_WRAPPER;

architecture behv of HDLC_TXRX_WRAPPER is

  type txrx256b_24ch_type       is array (23 downto 0) of std_logic_vector(REG_WIDTH-1 downto 0);
  signal rx_ic_reg              : txrx256b_24ch_type;
  signal tx_ic_reg              : txrx256b_24ch_type;
  signal rx_ec_reg              : txrx256b_24ch_type;
  signal tx_ec_reg              : txrx256b_24ch_type;

  signal ic_trig                : std_logic_vector(23 downto 0);
  signal ec_trig                : std_logic_vector(23 downto 0);
  signal IC_RX_REG_BUF          : std_logic_vector(REG_WIDTH-1 downto 0);
  signal EC_RX_REG_BUF          : std_logic_vector(REG_WIDTH-1 downto 0);
  signal ic_ch_sel              : std_logic_vector(4 downto 0);
  signal ec_ch_sel              : std_logic_vector(4 downto 0);
  signal ICEC_TX_4b_i           : txrx4b_type(0 to GBT_NUM-1);
  signal ICEC_RX_4b_i           : txrx4b_type(0 to GBT_NUM-1);
  signal ic_trig_i              : std_logic_vector(23 downto 0):=x"000000";
  signal ic_trig_r              : std_logic_vector(23 downto 0):=x"000000";
  signal ic_trig_2r             : std_logic_vector(23 downto 0):=x"000000";
  signal ic_trig_3r             : std_logic_vector(23 downto 0):=x"000000";
  signal ic_sel_rx_i            : std_logic_vector(23 downto 0):=x"000000";
  signal IC_busy_pull           : std_logic_vector(23 downto 0):=x"000000";
  signal ic_int                 : std_logic_vector(23 downto 0):=x"000000";
  signal ec_trig_i              : std_logic_vector(23 downto 0):=x"000000";
  signal ec_trig_r              : std_logic_vector(23 downto 0):=x"000000";
  signal ec_trig_2r             : std_logic_vector(23 downto 0):=x"000000";
  signal ec_trig_3r             : std_logic_vector(23 downto 0):=x"000000";
  signal EC_busy_pull           : std_logic_vector(23 downto 0):=x"000000";
  signal ec_int                 : std_logic_vector(23 downto 0):=x"000000";
  signal muxsel                 : std_logic_vector(23 downto 0);

begin

  ic_trig_i(4 downto 0)         <= register_map_control.ICEC_TRIG(4 downto 0);
  ic_sel_rx_i(4 downto 0)       <= register_map_control.ICEC_TRIG(20 downto 16);
  ec_trig_i(4 downto 0)         <= register_map_control.ICEC_TRIG(12 downto 8);




  
  tx_ec_reg(0) <= register_map_control.EC_TXDATA03 &  register_map_control.EC_TXDATA02
                  &  register_map_control.EC_TXDATA01 &  register_map_control.EC_TXDATA00;
  tx_ec_reg(1) <= register_map_control.EC_TXDATA13 &  register_map_control.EC_TXDATA12
                  &  register_map_control.EC_TXDATA11 &  register_map_control.EC_TXDATA10;
  tx_ec_reg(2) <= register_map_control.EC_TXDATA23 &  register_map_control.EC_TXDATA22
                  &  register_map_control.EC_TXDATA21 &  register_map_control.EC_TXDATA20;
  tx_ec_reg(3) <= register_map_control.EC_TXDATA33 &  register_map_control.EC_TXDATA32
                  &  register_map_control.EC_TXDATA31 &  register_map_control.EC_TXDATA30;
  tx_ec_reg(4) <= register_map_control.EC_TXDATA43 &  register_map_control.EC_TXDATA42
                  &  register_map_control.EC_TXDATA41 &  register_map_control.EC_TXDATA40;
  

  ch_gen : for i in GBT_NUM-1 downto 0 generate
    tx_ic_reg(i) <= register_map_control.IC_TXDATA03 &  register_map_control.IC_TXDATA02
                    &  register_map_control.IC_TXDATA01 &  register_map_control.IC_TXDATA00;           
                    
    process (txclk_40m)
    begin
      if txclk_40m'event and txclk_40m='1' then
        ic_trig_r(i)    <= ic_trig_i(i);
        ic_trig_2r(i)   <= ic_trig_r(i);
        ic_trig_3r(i)   <= ic_trig_2r(i);
        IC_busy_pull(i) <= ic_trig_r(i) and (not ic_trig_3r(i));
        ic_trig(i)      <= ic_trig_r(i) and (not ic_trig_2r(i));
         
        ec_trig_r(i)    <= ec_trig_i(i);
        ec_trig_2r(i)   <= ec_trig_r(i);
        ec_trig_3r(i)   <= ec_trig_2r(i);
        EC_busy_pull(i) <= ec_trig_r(i) and (not ec_trig_3r(i));
        ec_trig(i)      <= ec_trig_r(i) and (not ec_trig_2r(i));
         
      end if;
    end process;
    
    process(rxclk_40m) 
    begin
      if rxclk_40m'event and rxclk_40m='1' then
        if ic_busy_pull(i) = '1' then
          ICECBUSY(i)   <= '1';
        elsif ic_int(i)='1' then
          ICECBUSY(i)   <= '0';
        end if;
        if ec_busy_pull(i)= '1' then
          ICECBUSY(i+8) <= '1';
        elsif ec_int(i)='1' then
          ICECBUSY(i+8) <= '0';
        end if;  
      end if;
    end process;              
  end generate;
  
  ICEC_INT_RX_DATA(3) <= IC_RX_REG_BUF(255 downto 192);
  ICEC_INT_RX_DATA(2) <= IC_RX_REG_BUF(191 downto 128);
  ICEC_INT_RX_DATA(1) <= IC_RX_REG_BUF(127 downto 64);
  ICEC_INT_RX_DATA(0) <= IC_RX_REG_BUF(63 downto 0);

  ICEC_INT_RX_DATA(7) <= rx_ec_reg(0)(255 downto 192);
  ICEC_INT_RX_DATA(6) <= rx_ec_reg(0)(191 downto 128);
  ICEC_INT_RX_DATA(5) <= rx_ec_reg(0)(127 downto 64);
  ICEC_INT_RX_DATA(4) <= rx_ec_reg(0)(63 downto 0);
  ICEC_INT_RX_DATA(11) <= rx_ec_reg(1)(255 downto 192);
  ICEC_INT_RX_DATA(10) <= rx_ec_reg(1)(191 downto 128);
  ICEC_INT_RX_DATA(9) <= rx_ec_reg(1)(127 downto 64);
  ICEC_INT_RX_DATA(8) <= rx_ec_reg(1)(63 downto 0);
  ICEC_INT_RX_DATA(15) <= rx_ec_reg(2)(255 downto 192);
  ICEC_INT_RX_DATA(14) <= rx_ec_reg(2)(191 downto 128);
  ICEC_INT_RX_DATA(13) <= rx_ec_reg(2)(127 downto 64);
  ICEC_INT_RX_DATA(12) <= rx_ec_reg(2)(63 downto 0);
  ICEC_INT_RX_DATA(19) <= rx_ec_reg(3)(255 downto 192);
  ICEC_INT_RX_DATA(18) <= rx_ec_reg(3)(191 downto 128);
  ICEC_INT_RX_DATA(17) <= rx_ec_reg(3)(127 downto 64);
  ICEC_INT_RX_DATA(16) <= rx_ec_reg(3)(63 downto 0);
  ICEC_INT_RX_DATA(23) <= rx_ec_reg(4)(255 downto 192);
  ICEC_INT_RX_DATA(22) <= rx_ec_reg(4)(191 downto 128);
  ICEC_INT_RX_DATA(21) <= rx_ec_reg(4)(127 downto 64);
  ICEC_INT_RX_DATA(20) <= rx_ec_reg(4)(63 downto 0);        

  IC_RX_REG_BUF <= rx_ic_reg(0)         when ic_sel_rx_i(0) = '1' else
                   rx_ic_reg(1)         when ic_sel_rx_i(1) = '1' else
                   rx_ic_reg(2)         when ic_sel_rx_i(2) = '1' else
                   rx_ic_reg(3)         when ic_sel_rx_i(3) = '1' else
                   rx_ic_reg(4)         when ic_sel_rx_i(4) = '1' else
                   IC_RX_REG_BUF;
                   

--  EC_RX_REG_BUF <= rx_ec_reg(0)         when ec_ch_sel = "00000" else
--                   rx_ec_reg(1)         when ec_ch_sel = "00001" else
--                   rx_ec_reg(2)         when ec_ch_sel = "00010" else
--                   rx_ec_reg(3)         when ec_ch_sel = "00011" else
--                   rx_ec_reg(4)         when ec_ch_sel = "00100" else
--                   rx_ec_reg(5)         when ec_ch_sel = "00101" else
--                   rx_ec_reg(6)         when ec_ch_sel = "00110" else
--                   rx_ec_reg(7)         when ec_ch_sel = "00111" else
--                   rx_ec_reg(8)         when ec_ch_sel = "01000" else
--                   rx_ec_reg(9)         when ec_ch_sel = "01001" else
--                   rx_ec_reg(10)        when ec_ch_sel = "01010" else
--                   rx_ec_reg(11)        when ec_ch_sel = "01011" else
--                   rx_ec_reg(12)        when ec_ch_sel = "01100" else
--                   rx_ec_reg(13)        when ec_ch_sel = "01101" else
--                   rx_ec_reg(14)        when ec_ch_sel = "01110" else
--                   rx_ec_reg(15)        when ec_ch_sel = "01111" else
--                   rx_ec_reg(16)        when ec_ch_sel = "10000" else
--                   rx_ec_reg(17)        when ec_ch_sel = "10001" else
--                   rx_ec_reg(18)        when ec_ch_sel = "10010" else
--                   rx_ec_reg(19)        when ec_ch_sel = "10011" else
--                   rx_ec_reg(20)        when ec_ch_sel = "10100" else
--                   rx_ec_reg(21)        when ec_ch_sel = "10101" else
--                   rx_ec_reg(22)        when ec_ch_sel = "10110" else
--                   rx_ec_reg(23)        when ec_ch_sel = "10111" else
--                   rx_ec_reg(0);
  
  ICEC_HDLC_TXRX_GEN : for i in GBT_NUM-1 downto 0 generate

    IC_HDLC_TXRX_inst : entity work.HDLC_TXRX
      generic map(
        REG_WIDTH         => REG_WIDTH
        )
      port map(
        rx_long_data_reg_o        => rx_ic_reg(i),
        tx_long_data_reg_i        => tx_ic_reg(i),

        tx_trig_i   => ic_trig(i),  --one tx40m cycle
        rx_trig_o   => ic_int(i), --one rx40m cycle
    
        txclk_40m => txclk_40m,
        rxclk_40m => rxclk_40m,

        IC_RX_2b  => ICEC_RX_4b(i)(3 downto 2),
        IC_TX_2b  => ICEC_TX_4b(i)(3 downto 2)

        );
  
    EC_HDLC_TXRX_inst : entity work.HDLC_TXRX
      generic map(
        REG_WIDTH         => 256
        )
      port map(
        rx_long_data_reg_o        => rx_ec_reg(i),
        tx_long_data_reg_i        => tx_ec_reg(i),

        tx_trig_i   => ec_trig(i),  --one tx40m cycle
        rx_trig_o   => ec_int(i), --one rx40m cycle
    
        txclk_40m => txclk_40m,
        rxclk_40m => rxclk_40m,

        IC_RX_2b  => ICEC_RX_4b_i(i)(1 downto 0),
        IC_TX_2b  => ICEC_TX_4b_i(i)(1 downto 0)

        );
 
    process(rxclk_40m)
    begin
      if rxclk_40m'event and rxclk_40m='1' then
        --if muxsel(i)='0' then
        ICEC_RX_4b_i(i)(1)      <= ICEC_RX_4b(i)(0);
        ICEC_RX_4b_i(i)(0)      <= ICEC_RX_4b(i)(1);
      --else
      -- ICEC_RX_4b_i(i)(0)     <= ICEC_RX_4b(i)(0);
      --ICEC_RX_4b_i(i)(1)      <= ICEC_RX_4b(i)(1);
      --end if;
      end if;
    end process;
 
    ICEC_TX_4b(i)(0) <= ICEC_TX_4b_i(i)(1);
    ICEC_TX_4b(i)(1) <= ICEC_TX_4b_i(i)(0);
  
  end generate;


end behv;
 
