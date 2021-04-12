----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 04/11/2021 06:00:10 PM
-- Design Name: 
-- Module Name: pipeline_10_stage_tb - Behavioral
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

entity pipeline_10_stage_tb is
--  Port ( );
end pipeline_10_stage_tb;

architecture Behavioral of pipeline_10_stage_tb is

    component pipeline_10_stage
        port (
            clk     : in STD_LOGIC;
            d_in    : in STD_LOGIC;
            d_out   : out STD_LOGIC
        );
    end component pipeline_10_stage;

    signal clk : std_logic := '0';
    constant clk_period : time := 1 ns;
    
    signal d_in : std_logic := '1';
    
    signal d_out : std_logic;

begin

   clk_process :process
   begin
        clk <= '0';
        wait for clk_period/2;  --for 0.5 ns signal is '0'.
        clk <= '1';
        wait for clk_period/2;  --for next 0.5 ns signal is '1'.
   end process;

    DUT : pipeline_10_stage
        port map (
            clk     => clk,
            d_in    => d_in,
            d_out   => d_out
        );

end Behavioral;
