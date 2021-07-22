----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 03/31/2021 07:24:23 PM
-- Design Name: 
-- Module Name: top - Behavioral
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
use ieee.std_logic_unsigned.all;
use IEEE.math_real.all;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

library xil_defaultlib;
use xil_defaultlib.math_functions.all;

entity board_top is
    Port ( 
           CPU_RESETN   : in STD_LOGIC;
           clk          : in STD_LOGIC;
           LED          : out STD_LOGIC_VECTOR(3 downto 0)
    );
end board_top;

architecture Behavioral of board_top is

    component top
        generic (
            -- Fox's algorithm network paramters
            FOX_NETWORK_STAGES  : integer := 2;
            FOX_NETWORK_NODES   : integer := 4
        );
        port (
            clk      : in std_logic;
            reset_n  : in std_logic;
            LED      : out STD_LOGIC_VECTOR((FOX_NETWORK_NODES-1) downto 0)
        );
    end component top;

    -- Fox's algorithm network paramters
    constant FOX_NETWORK_STAGES  : integer := 2;
    constant FOX_NETWORK_NODES   : integer := FOX_NETWORK_STAGES ** 2;
    
    signal clkdiv2  : std_logic := '0';

begin

    -- Clock divider
    CLOCK_DIVIDER: process (clk)
    begin
        if (rising_edge(clk)) then   
            clkdiv2 <= not clkdiv2;
        end if;
    end process CLOCK_DIVIDER;

    FOX_TOP: top
        generic map (
            FOX_NETWORK_STAGES  => FOX_NETWORK_STAGES,
            FOX_NETWORK_NODES   => FOX_NETWORK_NODES
        )
        port map (
            clk     => clkdiv2,
            reset_n => CPU_RESETN,
            LED     => LED
        );

end Behavioral;
