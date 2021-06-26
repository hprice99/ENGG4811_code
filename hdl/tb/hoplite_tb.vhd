----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 05/01/2021 07:39:41 PM
-- Design Name: 
-- Module Name: hoplite_tb - Behavioral
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

entity hoplite_tb is
end hoplite_tb;

architecture Behavioral of hoplite_tb is

    component hoplite_tb_node
    generic (
        X_COORD     : integer := 0;
        Y_COORD     : integer := 0;
        COORD_BITS  : integer := 2;
        BUS_WIDTH   : integer := 8
    );
    port ( 
        clk                 : in STD_LOGIC;
        reset_n             : in STD_LOGIC;
        x_dest              : in STD_LOGIC_VECTOR((COORD_BITS-1) downto 0);
        y_dest              : in STD_LOGIC_VECTOR((COORD_BITS-1) downto 0);
        trig                : in STD_LOGIC;
        x_in                : in STD_LOGIC_VECTOR((BUS_WIDTH-1) downto 0);
        x_in_valid          : in STD_LOGIC;
        y_in                : in STD_LOGIC_VECTOR((BUS_WIDTH-1) downto 0);
        y_in_valid          : in STD_LOGIC;
        x_out               : out STD_LOGIC_VECTOR((BUS_WIDTH-1) downto 0);
        x_out_valid         : out STD_LOGIC;
        y_out               : out STD_LOGIC_VECTOR((BUS_WIDTH-1) downto 0);
        y_out_valid         : out STD_LOGIC
    );
    end component hoplite_tb_node;
    
    signal clk          : std_logic := '0';
    constant clk_period : time := 1 ns;
    
    signal reset_n      : std_logic;
    
    constant NETWORK_ROWS   : integer := 2;
    constant NETWORK_COLS   : integer := 2;
    constant NETWORK_NODES  : integer := NETWORK_ROWS * NETWORK_COLS;
    constant COORD_BITS     : integer := 1;
    constant BUS_WIDTH      : integer := 4 * COORD_BITS;
    
    type t_Coordinate is array (0 to 1) of std_logic_vector((COORD_BITS-1) downto 0);
    constant X_INDEX    : integer := 0;
    constant Y_INDEX    : integer := 1;
    
    -- Array of message interfaces between nodes
    type t_Destination is array(0 to (NETWORK_COLS-1), 0 to (NETWORK_ROWS-1)) of t_Coordinate;
    type t_Message is array (0 to (NETWORK_COLS-1), 0 to (NETWORK_ROWS-1)) of std_logic_vector((BUS_WIDTH-1) downto 0);
    type t_MessageValid is array (0 to (NETWORK_COLS-1), 0 to (NETWORK_ROWS-1)) of std_logic;
    
--    signal x_messages, y_messages : t_Message := (others => (others => (others => '0')));
--    signal x_messages_valid, y_messages_valid : t_MessageValid := (others => (others => '0'));
--    signal trig : t_MessageValid := (others => (others => '0'));

    signal x_messages, y_messages : t_Message;
    signal destinations : t_Destination;
    signal x_messages_valid, y_messages_valid : t_MessageValid;
    signal trig : t_MessageValid;
    
    constant TEST_SRC_ROW : integer := 0;
    constant TEST_SRC_COL : integer := 0;

begin
    
    -- Generate clk and reset_n
    reset_n <= '0', '1' after clk_period;
    
    CLK_PROCESS: process
    begin
        clk <= '0';
        wait for clk_period/2;  --for 0.5 ns signal is '0'.
        clk <= '1';
        wait for clk_period/2;  --for next 0.5 ns signal is '1'.
    end process CLK_PROCESS;
    

    -- Generate the network
    NETWORK_ROW_GEN: for i in 0 to (NETWORK_ROWS-1) generate
        NETWORK_COL_GEN: for j in 0 to (NETWORK_COLS-1) generate
            constant prev_row : integer := ((i-1) mod NETWORK_ROWS);
            constant prev_col : integer := ((j-1) mod NETWORK_COLS);
            constant curr_row : integer := i;
            constant curr_col : integer := j;
            constant next_row : integer := ((i+1) mod NETWORK_ROWS);
            constant next_col : integer := ((j+1) mod NETWORK_COLS);
            begin
                -- Set destination
                destinations(curr_col, curr_row)(X_INDEX) <= std_logic_vector(to_unsigned(next_col, COORD_BITS));
                destinations(curr_col, curr_row)(Y_INDEX) <= std_logic_vector(to_unsigned(next_row, COORD_BITS));
            
                -- Instantiate node
                NODE: hoplite_tb_node
                generic map (
                    BUS_WIDTH   => BUS_WIDTH,
                    X_COORD     => i,
                    Y_COORD     => j,
                    COORD_BITS  => COORD_BITS
                )
                port map (
                    clk                 => clk,
                    reset_n             => reset_n,
                    x_dest              => destinations(curr_col, curr_row)(X_INDEX),
                    y_dest              => destinations(curr_col, curr_row)(Y_INDEX),
                    trig                => trig(curr_col, curr_row),
                    x_in                => x_messages(prev_col, curr_row),
                    x_in_valid          => x_messages_valid(prev_col, curr_row),                  
                    y_in                => y_messages(curr_col, prev_row),
                    y_in_valid          => y_messages_valid(curr_col, prev_row),
                    x_out               => x_messages(next_col, curr_row),
                    x_out_valid         => x_messages_valid(next_col, curr_row),
                    y_out               => y_messages(curr_col, next_row),
                    y_out_valid         => y_messages_valid(curr_col, next_row)
                );
            
            -- TODO Ensure that each node's trig is only one-bit
            TRIG_FF : process (clk)
                begin
                    if (rising_edge(clk)) then
                        if (reset_n = '0') then
                            trig(curr_row, curr_col) <= '0';
                            
--                            x_messages(curr_row, curr_col) <= (others => '0');
--                            y_messages(curr_row, curr_col) <= (others => '0');
                            
--                            x_messages_valid(curr_row, curr_col) <= '0';
--                            y_messages_valid(curr_row, curr_col) <= '0';
                        elsif (curr_row = TEST_SRC_ROW and curr_col = TEST_SRC_COL) then
                            trig(curr_row, curr_col) <= not trig(curr_row, curr_col);
                        end if;
                    end if;
            end process TRIG_FF;
        end generate NETWORK_COL_GEN;
    end generate NETWORK_ROW_GEN;

end Behavioral;
