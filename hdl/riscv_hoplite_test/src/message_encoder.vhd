----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 07/04/2021 09:50:10 PM
-- Design Name: 
-- Module Name: message_encoder - Behavioral
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
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity message_encoder is
    Generic (
        COORD_BITS      : integer := 2;
        MESSAGE_BITS    : integer := 32;
        BUS_WIDTH       : integer := 36
    );
    Port (
        clk                 : in std_logic;
        reset_n             : in std_logic;
        
        x_coord_in          : in std_logic_vector((COORD_BITS-1) downto 0);
        x_coord_in_valid    : in std_logic;
        
        y_coord_in          : in std_logic_vector((COORD_BITS-1) downto 0);
        y_coord_in_valid    : in std_logic;
        
        message_in          : in std_logic_vector((MESSAGE_BITS-1) downto 0);
        message_in_valid    : in std_logic;
        
        packet_in_complete  : in std_logic;
        
        packet_out          : out std_logic_vector((BUS_WIDTH-1) downto 0);
        packet_out_valid    : out std_logic
    );
end message_encoder;

architecture Behavioral of message_encoder is

    signal x_coord, y_coord : std_logic_vector((COORD_BITS-1) downto 0);
    signal message          : std_logic_vector((MESSAGE_BITS-1) downto 0);

begin

    -- Message format 0 -- x_dest | y_dest | messsage -- (BUS_WIDTH-1)
    packet_out          <= message & y_coord & x_coord;
    packet_out_valid    <= packet_in_complete; -- TODO May need to ensure that this only lasts one clock cycle (already done by system)
    
    FIELD_FF: process (clk)
    begin
        if (rising_edge(clk)) then
            if (reset_n = '0') then
                x_coord     <= (others => '0');
                y_coord     <= (others => '0');
                message     <= (others => '0');
            else
                if (x_coord_in_valid = '1') then
                    x_coord <= x_coord_in;
                end if;
                
                if (y_coord_in_valid = '1') then
                    y_coord <= y_coord_in;
                end if;
                
                if (message_in_valid = '1') then
                    message <= message_in;
                end if;
            end if;
        end if;
    end process FIELD_FF;

end Behavioral;
