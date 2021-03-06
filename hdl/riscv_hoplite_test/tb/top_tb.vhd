library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

use STD.textio.all;
use IEEE.std_logic_textio.all;

library xil_defaultlib;
use xil_defaultlib.random.all;
use xil_defaultlib.math_functions.all;

entity top_tb is
end top_tb;

architecture Behavioral of top_tb is

    component top
        port ( 
               CPU_RESETN   : in std_logic;
               CLK_100MHZ   : in std_logic;
               SW           : in std_logic_vector(3 downto 0);
               LED          : out std_logic_vector(3 downto 0)
        );
    end component top;
    
    signal clk          : std_logic := '0';
    constant clk_period : time := 10 ns;
    
    signal reset_n      : std_logic;
    
    signal switch   : std_logic_vector(3 downto 0);
    signal LED      : std_logic_vector(3 downto 0);
    
    signal count    : integer;
    
    constant SWITCH_THRESHOLD    : real := 0.5;

begin

    -- Generate clk and reset_n
    reset_n <= '0', '1' after 100*clk_period;
    
    CLK_PROCESS: process
    begin
        clk <= '0';
        wait for clk_period/2;
        clk <= '1';
        wait for clk_period/2;
    end process CLK_PROCESS;
    
    -- Construct message
    TOGGLE_SWITCHES: process (clk)
    begin
        if (rising_edge(clk)) then
            if (reset_n = '0') then
                count   <= 0;
                switch  <= (others => '0');
            else
                count   <= count + 1;
                
                if (count mod 100000 = 0 and count > 100) then
                    switch  <= rand_slv(4, count);
                end if;
            end if;
        end if;
    end process TOGGLE_SWITCHES;
    
    DUT: top
    port map (
        CPU_RESETN  => reset_n,
        CLK_100MHZ  => clk,
        
        SW          => switch,
        LED         => LED
    );

    -- Print LED values
    LED_PRINT: process (LED)
        variable my_line : line;
    begin
        write(my_line, string'("Cycle = "));
        write(my_line, count);
        
        write(my_line, string'(", switches = "));
        write(my_line, switch);
    
        write(my_line, string'(", LEDs = "));
        write(my_line, LED);
        
        writeline(output, my_line);
    end process LED_PRINT;

end Behavioral;
