----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 07/05/2021 09:08:38 PM
-- Design Name: 
-- Module Name: top_tb - Behavioral
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

entity top_tb is
end top_tb;

architecture Behavioral of top_tb is

    component top
        port ( 
               CPU_RESETN   : in STD_LOGIC;
               CLK_100MHZ   : in STD_LOGIC;
               SW           : in STD_LOGIC_VECTOR(3 downto 0);
               LED          : out STD_LOGIC_VECTOR(3 downto 0)
        );
    end component top;
    
    signal clk          : std_logic := '0';
    constant clk_period : time := 10 ns;
    
    signal reset_n      : std_logic;
    
    signal switch   : std_logic_vector(3 downto 0);
    signal LED      : std_logic_vector(3 downto 0);

begin

    -- Generate clk and reset_n
    reset_n <= '0', '1' after 100*clk_period;
    
    CLK_PROCESS: process
    begin
        clk <= '0';
        wait for clk_period/2;  --for 0.5 ns signal is '0'.
        clk <= '1';
        wait for clk_period/2;  --for next 0.5 ns signal is '1'.
    end process CLK_PROCESS;
    
    DUT: top
    port map (
        CPU_RESETN => reset_n,
        CLK_100MHZ  => clk,
        
        SW          => switch,
        LED         => LED
    );

end Behavioral;
