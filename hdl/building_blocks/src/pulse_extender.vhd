library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

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
