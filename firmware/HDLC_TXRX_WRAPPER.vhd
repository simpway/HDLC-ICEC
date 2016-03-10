-- Under GPL v3.0 license.
-- Kai Chen @ BNL
----------------------------------------------------------------------------------
-- Company:
-- Engineer: Kai Chen @ BNL
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
    REG_WIDTH   : integer := 256;
    GBT_NUM     : integer   := 24
    );
  port (
    
    txclk_40m   : in std_logic;
    rxclk_40m   : in std_logic;
    register_map_scic_monitor : out register_map_scic_monitor_type;
    register_map_control : in    register_map_control_type;
    ICEC_RX_4b    : in txrx4b_type;
    ICEC_TX_4b    : out txrx4b_type

    );
end HDLC_TXRX_WRAPPER;

architecture behv of HDLC_TXRX_WRAPPER is

  type txrx256b_24ch_type is array (23 downto 0) of std_logic_vector(REG_WIDTH-1 downto 0);
  signal rx_ic_reg, tx_ic_reg, rx_ec_reg, tx_ec_reg : txrx256b_24ch_type;

  signal ic_trig, ec_trig: std_logic_vector(23 downto 0);
  signal IC_RX_REG_BUF, EC_RX_REG_BUF: std_logic_vector(REG_WIDTH-1 downto 0);
  signal ic_ch_sel, ec_ch_sel : std_logic_vector(4 downto 0);
  signal ICEC_TX_4b_i, ICEC_RX_4b_i: txrx4b_type(0 to GBT_NUM-1);
  signal ic_trig_i, ic_trig_r, ic_trig_2r, ic_trig_3r, IC_busy_pull, ic_int:std_logic_vector(23 downto 0):=x"000000";
  signal ec_trig_i, ec_trig_r, ec_trig_2r, ec_trig_3r, EC_busy_pull, ec_int:std_logic_vector(23 downto 0):=x"000000";
 signal muxsel:std_logic_vector(23 downto 0);
begin

  ic_trig_i <= register_map_control.ICEC_TRIG(23 downto 0);
  ec_trig_i <= register_map_control.ICEC_TRIG(55 downto 32);

  ic_ch_sel <= register_map_control.ICEC_CHN_SEL(4 downto 0);
  ec_ch_sel <= register_map_control.ICEC_CHN_SEL(12 downto 8);
  muxsel <= register_map_control.ICEC_CHN_SEL(55 downto 32);

  ch_gen : for i in GBT_NUM-1 downto 0 generate
    tx_ic_reg(i) <= register_map_control.IC_TXDATA3 &  register_map_control.IC_TXDATA2
                    &  register_map_control.IC_TXDATA1 &  register_map_control.IC_TXDATA0;
    tx_ec_reg(i) <= register_map_control.EC_TXDATA3 &  register_map_control.EC_TXDATA2
                    &  register_map_control.EC_TXDATA1 &  register_map_control.EC_TXDATA0;
                    
                    
     process (txclk_40m)
     begin
     if txclk_40m'event and txclk_40m='1' then
         ic_trig_r(i) <= ic_trig_i(i);
         ic_trig_2r(i) <= ic_trig_r(i);
         ic_trig_3r(i) <= ic_trig_2r(i);
         IC_busy_pull(i) <= ic_trig_r(i) and (not ic_trig_3r(i));
         ic_trig(i) <= ic_trig_r(i) and (not ic_trig_2r(i));
         
         ec_trig_r(i) <= ec_trig_i(i);
          ec_trig_2r(i) <= ec_trig_r(i);
          ec_trig_3r(i) <= ec_trig_2r(i);
          EC_busy_pull(i) <= ec_trig_r(i) and (not ec_trig_3r(i));
          ec_trig(i) <= ec_trig_r(i) and (not ec_trig_2r(i));
         
     end if;
     end process;
     
     process(rxclk_40m) 
     begin
     if rxclk_40m'event and rxclk_40m='1' then
         if ic_busy_pull /= X"000000" then
             register_map_scic_monitor.ICECBUSY(i) <= '1';
         elsif ic_int(i)='1' then
             register_map_scic_monitor.ICECBUSY(i) <= '0';
         end if;
         if ec_busy_pull /= x"000000" then
              register_map_scic_monitor.ICECBUSY(i+32) <= '1';
        elsif ec_int(i)='1' then
              register_map_scic_monitor.ICECBUSY(i+32) <= '0';
          end if;  
     end if;
     end process;              
  end generate;

  register_map_scic_monitor.IC_RXDATA3 <= IC_RX_REG_BUF(255 downto 192);
  register_map_scic_monitor.IC_RXDATA2 <= IC_RX_REG_BUF(191 downto 128);
  register_map_scic_monitor.IC_RXDATA1 <= IC_RX_REG_BUF(127 downto 64);
  register_map_scic_monitor.IC_RXDATA0 <= IC_RX_REG_BUF(63 downto 0);

  register_map_scic_monitor.EC_RXDATA3 <= EC_RX_REG_BUF(255 downto 192);
  register_map_scic_monitor.EC_RXDATA2 <= EC_RX_REG_BUF(191 downto 128);
  register_map_scic_monitor.EC_RXDATA1 <= EC_RX_REG_BUF(127 downto 64);
  register_map_scic_monitor.EC_RXDATA0 <= EC_RX_REG_BUF(63 downto 0);

  IC_RX_REG_BUF <= rx_ic_reg(0)         when ic_ch_sel = "00000" else
                   rx_ic_reg(1)         when ic_ch_sel = "00001" else
                   rx_ic_reg(2)         when ic_ch_sel = "00010" else
                   rx_ic_reg(3)         when ic_ch_sel = "00011" else
                   rx_ic_reg(4)         when ic_ch_sel = "00100" else
                   rx_ic_reg(5)         when ic_ch_sel = "00101" else
                   rx_ic_reg(6)         when ic_ch_sel = "00110" else
                   rx_ic_reg(7)         when ic_ch_sel = "00111" else
                   rx_ic_reg(8)         when ic_ch_sel = "01000" else
                   rx_ic_reg(9)         when ic_ch_sel = "01001" else
                   rx_ic_reg(10)        when ic_ch_sel = "01010" else
                   rx_ic_reg(11)        when ic_ch_sel = "01011" else
                   rx_ic_reg(12)        when ic_ch_sel = "01100" else
                   rx_ic_reg(13)        when ic_ch_sel = "01101" else
                   rx_ic_reg(14)        when ic_ch_sel = "01110" else
                   rx_ic_reg(15)        when ic_ch_sel = "01111" else
                   rx_ic_reg(16)        when ic_ch_sel = "10000" else
                   rx_ic_reg(17)        when ic_ch_sel = "10001" else
                   rx_ic_reg(18)        when ic_ch_sel = "10010" else
                   rx_ic_reg(19)        when ic_ch_sel = "10011" else
                   rx_ic_reg(20)        when ic_ch_sel = "10100" else
                   rx_ic_reg(21)        when ic_ch_sel = "10101" else
                   rx_ic_reg(22)        when ic_ch_sel = "10110" else
                   rx_ic_reg(23)        when ic_ch_sel = "10111" else
                   rx_ic_reg(0);

  EC_RX_REG_BUF <= rx_ec_reg(0)         when ec_ch_sel = "00000" else
                   rx_ec_reg(1)         when ec_ch_sel = "00001" else
                   rx_ec_reg(2)         when ec_ch_sel = "00010" else
                   rx_ec_reg(3)         when ec_ch_sel = "00011" else
                   rx_ec_reg(4)         when ec_ch_sel = "00100" else
                   rx_ec_reg(5)         when ec_ch_sel = "00101" else
                   rx_ec_reg(6)         when ec_ch_sel = "00110" else
                   rx_ec_reg(7)         when ec_ch_sel = "00111" else
                   rx_ec_reg(8)         when ec_ch_sel = "01000" else
                   rx_ec_reg(9)         when ec_ch_sel = "01001" else
                   rx_ec_reg(10)        when ec_ch_sel = "01010" else
                   rx_ec_reg(11)        when ec_ch_sel = "01011" else
                   rx_ec_reg(12)        when ec_ch_sel = "01100" else
                   rx_ec_reg(13)        when ec_ch_sel = "01101" else
                   rx_ec_reg(14)        when ec_ch_sel = "01110" else
                   rx_ec_reg(15)        when ec_ch_sel = "01111" else
                   rx_ec_reg(16)        when ec_ch_sel = "10000" else
                   rx_ec_reg(17)        when ec_ch_sel = "10001" else
                   rx_ec_reg(18)        when ec_ch_sel = "10010" else
                   rx_ec_reg(19)        when ec_ch_sel = "10011" else
                   rx_ec_reg(20)        when ec_ch_sel = "10100" else
                   rx_ec_reg(21)        when ec_ch_sel = "10101" else
                   rx_ec_reg(22)        when ec_ch_sel = "10110" else
                   rx_ec_reg(23)        when ec_ch_sel = "10111" else
                   rx_ec_reg(0);
  
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
 begin if rxclk_40m'event and rxclk_40m='1' then
 if muxsel(i)='0' then
 ICEC_RX_4b_i(i)(1)<=ICEC_RX_4b(i)(0);
 ICEC_RX_4b_i(i)(0)<=ICEC_RX_4b(i)(1);
 else
  ICEC_RX_4b_i(i)(0)<=ICEC_RX_4b(i)(0);
 ICEC_RX_4b_i(i)(1)<=ICEC_RX_4b(i)(1);
 end if;
 end if;
 end process;
 
 ICEC_TX_4b(i)(0) <= ICEC_TX_4b_i(i)(1);
 ICEC_TX_4b(i)(1) <= ICEC_TX_4b_i(i)(0);
  
end generate;


end behv;
 
