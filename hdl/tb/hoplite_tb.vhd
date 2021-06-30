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
        clk                     : in STD_LOGIC;
        reset_n                 : in STD_LOGIC;
        count                   : in integer;
        
        x_dest                  : in STD_LOGIC_VECTOR((COORD_BITS-1) downto 0);
        y_dest                  : in STD_LOGIC_VECTOR((COORD_BITS-1) downto 0);
        trig                    : in STD_LOGIC;
        
        x_in                    : in STD_LOGIC_VECTOR((BUS_WIDTH-1) downto 0);
        x_in_valid              : in STD_LOGIC;
        y_in                    : in STD_LOGIC_VECTOR((BUS_WIDTH-1) downto 0);
        y_in_valid              : in STD_LOGIC;
        
        x_out                   : out STD_LOGIC_VECTOR((BUS_WIDTH-1) downto 0);
        x_out_valid             : out STD_LOGIC;
        y_out                   : out STD_LOGIC_VECTOR((BUS_WIDTH-1) downto 0);
        y_out_valid             : out STD_LOGIC;
        
        last_message_sent       : out STD_LOGIC_VECTOR ((BUS_WIDTH-1) downto 0);
        message_sent            : out STD_LOGIC;
        
        last_message_received   : out STD_LOGIC_VECTOR ((BUS_WIDTH-1) downto 0);
        message_received        : out STD_LOGIC
    );
    end component hoplite_tb_node;
    
    component fifo_sync
        generic (
            BUS_WIDTH   : integer := 32;
            FIFO_DEPTH  : integer := 64
        );
        port (
            clk         : in std_logic;
            reset_n     : in std_logic;

            write_en    : in std_logic;
            write_data  : in std_logic_vector((BUS_WIDTH-1) downto 0);

            read_en     : in std_logic;
            read_data   : out std_logic_vector((BUS_WIDTH-1) downto 0);

            full        : out std_logic;
            empty       : out std_logic
        );
    end component fifo_sync;
    
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
    type t_Trigger is array (0 to (NETWORK_COLS-1), 0 to (NETWORK_ROWS-1)) of std_logic;

    signal destinations : t_Destination;
    signal x_messages_out, y_messages_out : t_Message;
    signal x_messages_out_valid, y_messages_out_valid : t_MessageValid;
    signal x_messages_in, y_messages_in : t_Message;
    signal x_messages_in_valid, y_messages_in_valid : t_MessageValid;
    signal trig : t_Trigger;
    
    constant TEST_SRC_ROW : integer := 0;
    constant TEST_SRC_COL : integer := 0;

    -- Message checking FIFO
    type t_FifoMessage is array (0 to (NETWORK_COLS-1), 0 to (NETWORK_ROWS-1)) of t_Message;
    type t_FifoMessageValid is array (0 to (NETWORK_COLS-1), 0 to (NETWORK_ROWS-1)) of t_MessageValid;
    
    constant FIFO_DEPTH     : integer := MAX_MESSAGE_COUNT;
    
    -- Messages to send into checking FIFOs
    signal expected_messages_sent        : t_FifoMessage;
    signal expected_messages_sent_valid  : t_FifoMessageValid;
    
    signal expected_messages_received       : t_FifoMessage;
    signal expected_messages_received_valid : t_FifoMessageValid;
    
    -- Messages sent by processing elements
    signal last_messages_sent               : t_Message;
    signal last_messages_sent_destination   : t_Destination;
    signal messages_sent                    : t_MessageValid;

    -- Messages received by processing elements
    signal last_messages_received       : t_Message;
    signal last_messages_received_src   : t_Destination;
    signal messages_received            : t_MessageValid; 

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
                y_out_valid         => y_messages_out_valid(curr_col, curr_row),
                
                -- Messages sent by the contained processing element
                last_message_sent   => last_messages_sent(curr_col, curr_row),
                message_sent        => messages_sent(curr_col, curr_row),
                
                -- Messages received by the contained processing element
                last_message_received   => last_messages_received(curr_col, curr_row),
                message_received        => messages_received(curr_col, curr_row)
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
    
    -- Configure signals for message checking FIFO
    FIFO_SRC_ROW_CONTROL: for src_y in 0 to (NETWORK_ROWS-1) generate
        FIFO_SRC_COL_CONTROL: for src_x in 0 to (NETWORK_COLS-1) generate
        begin
            last_messages_sent_destination(src_x, src_y)(X_INDEX) <= last_messages_sent(src_x, src_y)((COORD_BITS-1) downto 0);
            last_messages_sent_destination(src_x, src_y)(Y_INDEX) <= last_messages_sent(src_x, src_y)((2*COORD_BITS-1) downto COORD_BITS);
            
            FIFO_DEST_ROW_CONTROL: for dest_y in 0 to (NETWORK_ROWS-1) generate
                FIFO_DEST_COL_CONTROL: for dest_x in 0 to (NETWORK_COLS-1) generate
                    constant src_y_signal : std_logic_vector((COORD_BITS-1) downto 0) := std_logic_vector(to_unsigned(src_y, COORD_BITS));
                    constant src_x_signal : std_logic_vector((COORD_BITS-1) downto 0) := std_logic_vector(to_unsigned(src_x, COORD_BITS));
                    constant dest_y_signal : std_logic_vector((COORD_BITS-1) downto 0) := std_logic_vector(to_unsigned(dest_y, COORD_BITS));
                    constant dest_x_signal : std_logic_vector((COORD_BITS-1) downto 0) := std_logic_vector(to_unsigned(dest_x, COORD_BITS));
                begin
                    last_messages_received_src(dest_x, dest_y)(X_INDEX) <= last_messages_received(dest_x, dest_y)((3*COORD_BITS-1) downto 2*COORD_BITS);
                    last_messages_received_src(dest_x, dest_y)(Y_INDEX) <= last_messages_received(dest_x, dest_y)((4*COORD_BITS-1) downto 3*COORD_BITS);
                
                    -- FIFO for checking messages are correctly routed
                    CHECK_FIFO: fifo_sync
                    generic map (
                        BUS_WIDTH   => BUS_WIDTH,
                        FIFO_DEPTH  => FIFO_DEPTH
                    )
                    port map (
                        clk         => clk,
                        reset_n     => reset_n,
                        
                        write_en    => expected_messages_sent_valid(src_x, src_y)(dest_x, dest_y),
                        write_data  => expected_messages_sent(src_x, src_y)(dest_x, dest_y),
                        
                        read_en     => expected_messages_received_valid(src_x, src_y)(dest_x, dest_y),
                        read_data   => expected_messages_received(src_x, src_y)(dest_x, dest_y),
                        
                        full        => open,
                        empty       => open
                    );
                    
                    -- Assign messages sent to the correct FIFO                   
                    ASSIGN_MESSAGE_SENT: process(clk)
                    begin
                        if (rising_edge(clk) and reset_n = '1') then
                            if (messages_sent(src_x, src_y) = '1' 
                                    and last_messages_sent_destination(src_x, src_y)(X_INDEX) = dest_x_signal
                                    and last_messages_sent_destination(src_x, src_y)(Y_INDEX) = dest_y_signal) then
                                expected_messages_sent_valid(src_x, src_y)(dest_x, dest_y)  <= '1';
                                expected_messages_sent(src_x, src_y)(dest_x, dest_y)        <= last_messages_sent(src_x, src_y);
                            else
                                expected_messages_sent_valid(src_x, src_y)(dest_x, dest_y)  <= '0';
                                expected_messages_sent(src_x, src_y)(dest_x, dest_y)        <= (others => '0');
                            end if;
                        end if;
                    end process ASSIGN_MESSAGE_SENT;
                    
                    -- Assign messages received to the correct FIFO
                    ASSIGN_MESSAGE_RECEIVED: process(clk)
                    begin
                        if (rising_edge(clk) and reset_n = '1') then
                            if (messages_received(dest_x, dest_y) = '1' 
                                    and last_messages_received_src(dest_x, dest_y)(X_INDEX) = src_x_signal
                                    and last_messages_received_src(dest_x, dest_y)(Y_INDEX) = src_y_signal) then
                                expected_messages_received_valid(src_x, src_y)(dest_x, dest_y)  <= '1';
                            else
                                expected_messages_received_valid(src_x, src_y)(dest_x, dest_y)  <= '0';
                            end if;
                        end if;
                    end process ASSIGN_MESSAGE_RECEIVED;
                end generate FIFO_DEST_COL_CONTROL;
            end generate FIFO_DEST_ROW_CONTROL;
        end generate FIFO_SRC_COL_CONTROL;
    end generate FIFO_SRC_ROW_CONTROL;
        
    
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
