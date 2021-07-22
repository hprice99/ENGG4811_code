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
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

use STD.textio.all;
use IEEE.std_logic_textio.all;

library xil_defaultlib;
use xil_defaultlib.fox_defs.all;

entity top_tb is
end top_tb;

architecture Behavioral of top_tb is

    component top
        generic (
            -- Fox's algorithm network paramters
            FOX_NETWORK_STAGES  : integer := 2;
            FOX_NETWORK_NODES   : integer := 4
        );
        port (
            clk                 : in std_logic;
            reset_n             : in std_logic;
            LED                 : out STD_LOGIC_VECTOR((FOX_NETWORK_NODES-1) downto 0);
            out_char            : out t_Char;
            out_char_en         : out t_MessageValid;
            out_matrix          : out t_Matrix;
            out_matrix_en       : out t_MessageValid;
            out_matrix_end_row  : out t_MessageValid;
            out_matrix_end      : out t_MessageValid
        );
    end component top;
    
    signal clk          : std_logic := '0';
    constant clk_period : time := 10 ns;
    
    signal reset_n      : std_logic;
    
    signal LED      : std_logic_vector((FOX_NETWORK_NODES-1) downto 0);
    
    signal count    : integer;

    signal out_char     : t_Char;
    signal out_char_en  : t_MessageValid;

    signal out_matrix           : t_Matrix;
    signal out_matrix_en        : t_MessageValid;
    signal out_matrix_end_row   : t_MessageValid;
    signal out_matrix_end       : t_MessageValid;

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

    COUNTER: process (clk)
    begin
        if (rising_edge(clk)) then
            if (reset_n = '0') then
                count   <= 0;
            else
                count   <= count + 1;
            end if;
        end if;
    end process COUNTER;

    FOX_TOP: top
        generic map (
            FOX_NETWORK_STAGES  => FOX_NETWORK_STAGES,
            FOX_NETWORK_NODES   => FOX_NETWORK_NODES
        )
        port map (
            clk                 => clk,
            reset_n             => reset_n,
            LED                 => LED,
            out_char            => out_char,
            out_char_en         => out_char_en,
            out_matrix          => out_matrix,
            out_matrix_en       => out_matrix_en,
            out_matrix_end_row  => out_matrix_end_row,
            out_matrix_end      => out_matrix_end
        );

    -- Generate the network
    CHAR_OUTPUT_ROW_GEN: for i in 0 to (NETWORK_ROWS-1) generate
        CHAR_OUTPUT_COL_GEN: for j in 0 to (NETWORK_COLS-1) generate
            constant curr_y         : integer := i;
            constant curr_x         : integer := j;
        begin
            CHAR_OUTPUT: process (clk)
                variable my_line : line;
            begin
                if (rising_edge(clk) and reset_n = '1') then
                    if (out_char_en(curr_x, curr_y) = '1') then
                        if (to_integer(unsigned(out_char(curr_x, curr_y))) = 10) then
                            writeline(output, my_line);
                        else
                            write(my_line, out_char(curr_x, curr_y));
                        end if;
                    end if;
                end if;
            end process CHAR_OUTPUT;
        end generate CHAR_OUTPUT_COL_GEN;
    end generate CHAR_OUTPUT_ROW_GEN;

end Behavioral;
