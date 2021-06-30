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
use IEEE.math_real.all;

use STD.textio.all;
use IEEE.std_logic_textio.all;

use std.env.finish;
use std.env.stop;

library xil_defaultlib;
use xil_defaultlib.hoplite_network_tb_defs.all;
use xil_defaultlib.math_functions.all;

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
        count               : in integer;
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
    constant clk_period : time := 50 ns;
    
    signal reset_n      : std_logic;
    
    signal count            : integer;
    
    constant NETWORK_ROWS   : integer := 2;
    constant NETWORK_COLS   : integer := 2;
    constant NETWORK_NODES  : integer := NETWORK_ROWS * NETWORK_COLS;
    constant COORD_BITS     : integer := ceil_log2(max(NETWORK_ROWS, NETWORK_COLS));
    constant BUS_WIDTH      : integer := 4 * COORD_BITS + MESSAGE_BITS;
    
    type t_Coordinate is array (0 to 1) of std_logic_vector((COORD_BITS-1) downto 0);
    constant X_INDEX    : integer := 0;
    constant Y_INDEX    : integer := 1;
    
    -- Array of message interfaces between nodes
    type t_Destination is array(0 to (NETWORK_COLS-1), 0 to (NETWORK_ROWS-1)) of t_Coordinate;
    type t_Message is array (0 to (NETWORK_COLS-1), 0 to (NETWORK_ROWS-1)) of std_logic_vector((BUS_WIDTH-1) downto 0);
    type t_MessageValid is array (0 to (NETWORK_COLS-1), 0 to (NETWORK_ROWS-1)) of std_logic;

    signal destinations : t_Destination;
    signal x_messages_out, y_messages_out : t_Message;
    signal x_messages_out_valid, y_messages_out_valid : t_MessageValid;
    signal x_messages_in, y_messages_in : t_Message;
    signal x_messages_in_valid, y_messages_in_valid : t_MessageValid;
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
            -- destinations(curr_col, curr_row)(Y_INDEX) <= std_logic_vector(to_unsigned(curr_row, COORD_BITS));
        
            -- Instantiate node
            NODE: hoplite_tb_node
            generic map (
                BUS_WIDTH   => BUS_WIDTH,
                X_COORD     => curr_col,
                Y_COORD     => curr_row,
                COORD_BITS  => COORD_BITS
            )
            port map (
                clk                 => clk,
                reset_n             => reset_n,
                count               => count,
                
                -- Signals to create outgoing messages
                x_dest              => destinations(curr_col, curr_row)(X_INDEX),
                y_dest              => destinations(curr_col, curr_row)(Y_INDEX),
                trig                => trig(curr_col, curr_row),
                
                -- Messages incoming to router
                x_in                => x_messages_in(curr_col, curr_row),
                x_in_valid          => x_messages_in_valid(curr_col, curr_row),                  
                y_in                => y_messages_in(curr_col, curr_row),
                y_in_valid          => y_messages_in_valid(curr_col, curr_row),
                
                -- Messages outgoing from router
                x_out               => x_messages_out(curr_col, curr_row),
                x_out_valid         => x_messages_out_valid(curr_col, curr_row),
                y_out               => y_messages_out(curr_col, curr_row),
                y_out_valid         => y_messages_out_valid(curr_col, curr_row)
            );
            
            -- Connect in and out messages
            x_messages_in(curr_col, curr_row)       <= x_messages_out(prev_col, curr_row);
            x_messages_in_valid(curr_col, curr_row) <= x_messages_out_valid(prev_col, curr_row);
            
            y_messages_in(curr_col, curr_row)       <= y_messages_out(curr_col, prev_row);
            y_messages_in_valid(curr_col, curr_row) <= y_messages_out_valid(curr_col, prev_row);

            TRIG_FF : process (clk)
            begin
                if (rising_edge(clk)) then
                    if (reset_n = '0') then
                        trig(curr_row, curr_col) <= '0';
                    elsif (curr_row = TEST_SRC_ROW and curr_col = TEST_SRC_COL) then
                    -- elsif (curr_row = TEST_SRC_ROW) then
                        if (count <= MAX_MESSAGE_COUNT) then
                            trig(curr_row, curr_col) <= not trig(curr_row, curr_col);
                        else
                            trig(curr_row, curr_col) <= '0';
                        end if;
                    end if;
                end if;
            end process TRIG_FF;
        end generate NETWORK_COL_GEN;
    end generate NETWORK_ROW_GEN;
    
    COUNTER: process(clk)
        variable my_line : line;
    begin
        if (rising_edge(clk)) then
            if (reset_n = '0') then
                count <= 0;
            else
                count   <= count + 1;
                
                write(my_line, string'(CR & LF & "Cycle "));
                write(my_line, count);           
                writeline(output, my_line);
                
                if (count = MAX_COUNT) then
                    stop;
                end if;
            end if;
        end if;
    end process COUNTER;

end Behavioral;
