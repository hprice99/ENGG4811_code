library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity pulse_extender is
    Port ( 
        clk         : in std_logic;
        reset_n     : in std_logic;
        trigger     : in std_logic;
        release     : in std_logic;
        pulse       : out std_logic
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
