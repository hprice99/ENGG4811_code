library IEEE;
use IEEE.STD_LOGIC_1164.ALL;


entity pipeline_tb is

end pipeline_tb;

architecture Behavioral of pipeline_tb is

    component pipeline
        generic (
             STAGES : integer := 10
        );
        port (
            clk     : in std_logic;
            d_in    : in std_logic;
            d_out   : out std_logic
        );
    end component pipeline;

    signal clk : std_logic := '0';
    constant clk_period : time := 1 ns;
    
    signal d_in : std_logic := '1';
    
    signal d_out : std_logic;

begin

   clk_process :process
   begin
        clk <= '0';
        wait for clk_period/2;
        clk <= '1';
        wait for clk_period/2;
   end process;

    DUT : pipeline
        generic map (
            STAGES  => 15
        )
        port map (
            clk     => clk,
            d_in    => d_in,
            d_out   => d_out
        );

end Behavioral;
