----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 04/11/2021 07:16:24 PM
-- Design Name: 
-- Module Name: pipeline - Behavioral
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

entity pulse_extender is
    Port ( 
        clk         : in STD_LOGIC;
        reset_n     : in STD_LOGIC;
        trigger     : in STD_LOGIC;
        release     : in STD_LOGIC;
        pulse       : out STD_LOGIC
    );
end pulse_extender;

architecture Behavioral of pulse_extender is

begin

    EXTENDER : process (clk)
    begin
        if (rising_edge(clk)) then
            if (reset_n = '0' or release = '1') then
                pulse <= '0';
            elsif (trigger = '1') then
                pulse <= '1';
            end if;
        end if;
    end process EXTENDER;

end Behavioral;
