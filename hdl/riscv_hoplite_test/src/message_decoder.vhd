----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 07/04/2021 09:50:10 PM
-- Design Name: 
-- Module Name: message_decoder - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity message_decoder is
    Generic (
        COORD_BITS      : integer := 2;
        MESSAGE_BITS    : integer := 32;
        BUS_WIDTH       : integer := 36
    );
    Port (
        clk                 : in std_logic;
        reset_n             : in std_logic;
        
        packet_in           : in std_logic_vector((BUS_WIDTH-1) downto 0);
        packet_in_valid     : in std_logic;
        
        x_coord_out         : out std_logic_vector((COORD_BITS-1) downto 0);
        y_coord_out         : out std_logic_vector((COORD_BITS-1) downto 0);
        message_out         : out std_logic_vector((MESSAGE_BITS-1) downto 0);
        packet_out_valid    : out std_logic;
        
        packet_read         : in std_logic
    );
end message_decoder;

architecture Behavioral of message_decoder is

    signal latest_packet    : std_logic_vector((BUS_WIDTH-1) downto 0);

begin
    -- latest_packet       <= packet_in;
    -- packet_out_valid    <= packet_in_valid;
    
    -- Message format 0 -- x_dest | y_dest | messsage -- (BUS_WIDTH-1)
    x_coord_out <= latest_packet((COORD_BITS-1) downto 0);
    y_coord_out <= latest_packet((2*COORD_BITS-1) downto COORD_BITS);
    message_out <= latest_packet((BUS_WIDTH-1) downto 2*COORD_BITS);
    
    PACKET_FF: process (clk)
    begin
        if (rising_edge(clk)) then
            if (reset_n = '0') then
                latest_packet   <= (others => '0');
            elsif (packet_in_valid = '1') then
                latest_packet   <= packet_in;
            end if;
        end if;
    end process PACKET_FF;
    
    -- Hold packet_out_valid high from when packet_in_valid is high to when the message is read, then reset
    VALID_FF: process (clk)
    begin
        if (rising_edge(clk)) then
            if (reset_n = '0') then
                packet_out_valid <= '0';
            else
                if (packet_read <= '1') then
                    packet_out_valid <= '0';
                elsif (packet_in_valid = '1') then
                    packet_out_valid <= '1';
                end if;
            end if;
        end if;
    end process VALID_FF;

end Behavioral;
