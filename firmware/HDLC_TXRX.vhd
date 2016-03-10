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


entity HDLC_TXRX is
  generic (
    REG_WIDTH           : integer   := 256
    );
  port (
    
    rx_long_data_reg_o  : out std_logic_vector(REG_WIDTH-1 downto 0);
    tx_long_data_reg_i  : in std_logic_vector(REG_WIDTH-1 downto 0);

    tx_trig_i             : in std_logic;
    rx_trig_o           : out std_logic;
    
    txclk_40m           : in std_logic;
    rxclk_40m           : in std_logic;

    IC_RX_2b            : in std_logic_vector(1 downto 0);
    IC_TX_2b            : out std_logic_vector(1 downto 0)

    );
end HDLC_TXRX;

architecture behv of HDLC_TXRX is


  signal tx_long_data_reg, tx_long_data, rx_long_data_reg, rx_long_data : std_logic_vector(REG_WIDTH-1 downto 0);
  signal rx_trig, rx_trig_r, rx_trig_2r : std_logic := '0';
  signal RX_IDLE : std_logic := '1';
  
begin
  
    
  rx_long_data_reg_o    <= rx_long_data_reg;
  tx_long_data_reg      <= tx_long_data_reg_i;
    
process(txclk_40m)
begin
  if txclk_40m'event and txclk_40m='1' then

    if tx_trig_i = '1' then
      tx_long_data      <= tx_long_data_reg; 
    else
      tx_long_data      <= "11" & tx_long_data(255 downto 2); 
    end if; 
      
    IC_TX_2b    <= tx_long_data(1 downto 0);
  end if;
end process;

process(rxclk_40m)
begin
  if rxclk_40m'event and rxclk_40m = '1' then
    rx_long_data        <= IC_RX_2b & rx_long_data(255 downto 2);
    rx_trig_r   <= rx_trig;
    rx_trig_2r  <= rx_trig_r;
    rx_trig_o   <= rx_trig_2r;
    if rx_long_data(7 downto 0) = "01111110" and RX_IDLE = '1' then
      rx_long_data_reg  <= rx_long_data;
      rx_trig   <= '1';
    elsif rx_long_data(8 downto 1) = "01111110" and RX_IDLE = '1' then
      rx_long_data_reg  <= '1' & rx_long_data(255 downto 1);
      rx_trig   <= '1';  
    else
      rx_trig   <= '0';
    end if;
 --   if rx_trig_2r = '1' then
 --     rx_long_data_reg  <= rx_long_data;
 --   else
 --     rx_long_data_reg  <= rx_long_data_reg;
 --   end if;

    if  rx_long_data(7 downto 0) = "11111111" or rx_long_data(7 downto 0) = "11111110" or rx_long_data(7 downto 0) = "01111111"  then
      RX_IDLE   <= '1';
    elsif rx_trig='1' then
       RX_IDLE   <= '0';
    else
      RX_IDLE   <= RX_IDLE;
    end if;
      
  end if;
end process;

end behv;
