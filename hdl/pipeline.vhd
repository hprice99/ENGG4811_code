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

entity pipeline is
    Generic (
        STAGES : integer := 10
    );
    Port ( 
        clk : in STD_LOGIC;
        d_in : in STD_LOGIC;
        d_out : out STD_LOGIC
    );
end pipeline;

architecture Behavioral of pipeline is

    signal d, q : std_logic_vector(STAGES-1 downto 0);

begin

    d(0)        <= d_in;
    d_out       <= q(STAGES-1);

    PIPELINE_STAGES_GEN: for i in 0 to (STAGES-1) generate
        PIPELINE_PROC : process (clk)
        begin
            if (rising_edge(clk)) then
                q(i) <= d(i);
            end if;
        end process PIPELINE_PROC;
        
        SHIFT : if i < (STAGES-1) generate
            d(i+1) <= q(i);
        end generate SHIFT;
    end generate PIPELINE_STAGES_GEN;

end Behavioral;
