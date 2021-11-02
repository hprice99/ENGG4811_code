library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity pipeline is
    Generic (
        STAGES : integer := 10
    );
    Port ( 
        clk : in std_logic;
        d_in : in std_logic;
        d_out : out std_logic
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
