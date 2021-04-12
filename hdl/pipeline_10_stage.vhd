----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 04/11/2021 05:53:45 PM
-- Design Name: 
-- Module Name: pipeline_10_stage - Behavioral
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

entity pipeline_10_stage is
    Port ( 
        clk : in STD_LOGIC;
        d_in : in STD_LOGIC;
        d_out : out STD_LOGIC
    );
end pipeline_10_stage;

architecture Behavioral of pipeline_10_stage is

    signal q1, q2, q3, q4, q5, q6, q7, q8, q9, q10 : std_logic;

begin

    PIPELINE_PROC : process (clk)
        begin
            if (rising_edge(clk)) then
                q1 <= d_in;
                q2 <= q1;
                q3 <= q2;
                q4 <= q3;
                q5 <= q4;
                q6 <= q5;
                q7 <= q6;
                q8 <= q7;
                q9 <= q8;
                q10 <= q9;
            end if;
        end process;
    
    d_out <= q10;
    
end Behavioral;
