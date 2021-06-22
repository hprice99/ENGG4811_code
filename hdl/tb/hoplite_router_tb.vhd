----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 05/01/2021 04:29:30 PM
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

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

library xil_defaultlib;
use xil_defaultlib.random.all;
use xil_defaultlib.math_functions.all;

use std.env.finish;

entity hoplite_router_tb is
end hoplite_router_tb;

architecture Behavioral of hoplite_router_tb is
    
    component hoplite_router
        generic (
            BUS_WIDTH   : integer := 32;
            X_COORD     : integer := 0;
            Y_COORD     : integer := 0;
            COORD_BITS  : integer := 1
        );
        port (
            clk             : in STD_LOGIC;
            reset_n         : in STD_LOGIC;
            x_in            : in STD_LOGIC_VECTOR((BUS_WIDTH-1) downto 0);
            x_in_valid      : in STD_LOGIC;
            y_in            : in STD_LOGIC_VECTOR((BUS_WIDTH-1) downto 0);
            y_in_valid      : in STD_LOGIC;
            pe_in           : in STD_LOGIC_VECTOR((BUS_WIDTH-1) downto 0);
            pe_in_valid     : in STD_LOGIC;
            x_out           : out STD_LOGIC_VECTOR((BUS_WIDTH-1) downto 0);
            x_out_valid     : out STD_LOGIC;
            y_out           : out STD_LOGIC_VECTOR((BUS_WIDTH-1) downto 0);
            y_out_valid     : out STD_LOGIC;
            pe_out          : out STD_LOGIC_VECTOR((BUS_WIDTH-1) downto 0);
            pe_out_valid    : out STD_LOGIC;
            pe_backpressure : out STD_LOGIC
        );
    end component hoplite_router;
    
    component synchronous_FIFO_with_block_RAM
        generic (
            W   : natural := 16;
            D   : natural := 65536;
            B   : natural := 16
        );
        port (
           reset_n  : in  STD_LOGIC;
           clock    : in  STD_LOGIC;
           enR      : in  STD_LOGIC;
           enW      : in  STD_LOGIC;
           emptyR   : out  STD_LOGIC;
           fullW    : out  STD_LOGIC;
           dataR    : out  STD_LOGIC_VECTOR (B-1 downto 0);
           dataW    : in  STD_LOGIC_VECTOR (B-1 downto 0)
        );
    end component synchronous_FIFO_with_block_RAM;
    
    constant MAX_CYCLES         : integer := 100;
    constant VALID_THRESHOLD    : real := 0.75;
    constant PE_IN_THRESHOLD    : real := 0.10;
    
    constant X_COORD    : integer := 0;
    constant Y_COORD    : integer := 0;
    constant COORD_BITS : integer := 2;
    constant BUS_WIDTH  : integer := 4 * COORD_BITS;
    constant DATA_WIDTH : integer := BUS_WIDTH-2*COORD_BITS;
    
    constant NETWORK_ROWS : integer := 2 ** COORD_BITS;
    constant NETWORK_COLS : integer := 2 ** COORD_BITS;
    
    signal count        : integer;
    
    constant X_INDEX    : integer := 0;
    constant Y_INDEX    : integer := 1;
    
    type t_Coordinate is array (0 to 1) of std_logic_vector((COORD_BITS-1) downto 0);
    signal x_message_dest, y_message_dest : t_Coordinate;
    
    signal x_message_data, y_message_data : std_logic_vector((DATA_WIDTH-1) downto 0);
    
    signal x_message_b, y_message_b             : std_logic_vector((BUS_WIDTH-1) downto 0);
    signal x_message_b_valid, y_message_b_valid : std_logic;
    
    signal x_message_r, y_message_r             : std_logic_vector((BUS_WIDTH-1) downto 0);
    signal x_message_r_valid, y_message_r_valid : std_logic;
    
    signal x_out        : std_logic_vector((BUS_WIDTH-1) downto 0);
    signal x_out_valid  : std_logic;
    
    signal y_out        : std_logic_vector((BUS_WIDTH-1) downto 0);
    signal y_out_valid  : std_logic;
    
    signal pe_out       : std_logic_vector((BUS_WIDTH-1) downto 0);
    signal pe_out_valid : std_logic;
    
    signal clk          : std_logic := '0';
    constant clk_period : time := 10 ns;
    
    signal reset_n      : std_logic;
        
    signal fifo_en_w, fifo_en_r     : std_logic;
    signal fifo_empty, fifo_full    : std_logic;
    signal fifo_data_w, fifo_data_r : std_logic_vector((BUS_WIDTH-1) downto 0);
    constant FIFO_ADDRESS_WIDTH     : natural := ceil_log2(MAX_CYCLES);
    constant FIFO_RAM_DEPTH         : natural := 2 ** FIFO_ADDRESS_WIDTH;
    constant FIFO_DATA_WIDTH        : natural := BUS_WIDTH; 
    
    signal fifo_r_valid : std_logic;
    
    signal last_pe_message_received : std_logic_vector((BUS_WIDTH-1) downto 0);
    
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
    
    -- Construct message
    CONSTRUCT_MESSAGE: process (clk)
    begin
        if (rising_edge(clk) and count <= MAX_CYCLES) then
            if (reset_n = '0') then
                count <= 0;
                
                x_message_dest(X_INDEX) <= (others => '0');
                x_message_dest(Y_INDEX) <= (others => '0');
                x_message_data          <= (others => '0');
                x_message_b_valid   <= '0';

                y_message_dest(X_INDEX) <= (others => '0');
                y_message_dest(Y_INDEX) <= (others => '0');
                y_message_data          <= (others => '0');
                y_message_b_valid   <= '0';
            else
                count <= count + 1;
                
                x_message_dest(X_INDEX) <= rand_slv(COORD_BITS, count);
                x_message_dest(Y_INDEX) <= rand_slv(COORD_BITS, 2*count);
                x_message_data          <= rand_slv(DATA_WIDTH, 3*count);
                x_message_b_valid       <= rand_logic(VALID_THRESHOLD, count);
                
                y_message_dest(X_INDEX) <= rand_slv(COORD_BITS, MAX_CYCLES-count);
                y_message_dest(Y_INDEX) <= rand_slv(COORD_BITS, 2*MAX_CYCLES-count);
                y_message_data          <= rand_slv(DATA_WIDTH, 3*MAX_CYCLES-count);
                y_message_b_valid       <= rand_logic(VALID_THRESHOLD, MAX_CYCLES-count);
            end if;
        end if;
    end process CONSTRUCT_MESSAGE;
    
    -- Packet format LSB x_dest|y_dest|data MSB                    
    x_message_b <= x_message_data & x_message_dest(Y_INDEX) & x_message_dest(X_INDEX);
    y_message_b <= y_message_data & y_message_dest(Y_INDEX) & y_message_dest(X_INDEX);
    
    MESSAGE_FF: process (clk)
    begin
        if (rising_edge(clk) and count <= MAX_CYCLES) then
            if (reset_n = '0') then
                x_message_r         <= (others => '0');
                x_message_r_valid   <= '0';
                
                y_message_r         <= (others => '0');
                y_message_r_valid   <= '0';
            else
                x_message_r         <= x_message_b;
                x_message_r_valid   <= x_message_b_valid;
                
                y_message_r         <= y_message_b;
                y_message_r_valid   <= y_message_b_valid;
            end if;
        end if;
    end process MESSAGE_FF;
    
    DUT: hoplite_router
    generic map (
        BUS_WIDTH   => BUS_WIDTH,
        X_COORD     => X_COORD,
        Y_COORD     => Y_COORD,
        COORD_BITS  => COORD_BITS
    )
    port map (
        clk                 => clk,
        reset_n             => reset_n,
        x_in                => x_message_r,
        x_in_valid          => x_message_r_valid,
        y_in                => y_message_r,
        y_in_valid          => y_message_r_valid,
        pe_in               => (others => '0'),
        pe_in_valid         => '0',
        x_out               => x_out,
        x_out_valid         => x_out_valid,
        y_out               => y_out,
        y_out_valid         => y_out_valid,
        pe_out              => pe_out,
        pe_out_valid        => pe_out_valid,
        pe_backpressure     => open
    );
    
    -- FIFO for checking messages
    FIFO: synchronous_FIFO_with_block_RAM
    generic map (
        W   => FIFO_ADDRESS_WIDTH,
        D   => FIFO_RAM_DEPTH,
        B   => FIFO_DATA_WIDTH
    )
    port map (
        reset_n => reset_n,
        clock   => clk,
        enR     => fifo_en_r,
        enW     => fifo_en_w,
        emptyR  => fifo_empty,
        fullW   => fifo_full,
        dataR   => fifo_data_r,
        dataW   => fifo_data_w
    );
    
    -- Writing to FIFO
    FIFO_WRITE: process (clk)
    begin
        if (rising_edge(clk) and count <= MAX_CYCLES) then
            if (reset_n = '0') then
                fifo_data_w <= (others => '0');
                fifo_en_w   <= '0';
            elsif (fifo_full = '0') then
                 if (x_message_b_valid = '1' and 
                        to_integer(unsigned(x_message_dest(X_INDEX))) = X_COORD and 
                        to_integer(unsigned(x_message_dest(Y_INDEX))) = Y_COORD) then
                    fifo_data_w     <= x_message_b;
                    fifo_en_w       <= '1';
                 elsif (y_message_b_valid = '1' and 
                            to_integer(unsigned(y_message_dest(X_INDEX))) = X_COORD and 
                            to_integer(unsigned(y_message_dest(Y_INDEX))) = Y_COORD) then
                    fifo_data_w     <= y_message_b;
                    fifo_en_w       <= '1';
                 else
                    fifo_en_w       <= '0';
                 end if;
            end if;
        end if;
    end process FIFO_WRITE;
    
    -- Read from FIFO
    FIFO_READ_ENABLE: process (fifo_empty, pe_out_valid)
    begin
        if (fifo_empty = '0') then
            fifo_en_r   <= pe_out_valid;
        else
            fifo_en_r   <= '0';
        end if;
    end process FIFO_READ_ENABLE;
    
    FIFO_READ_VALID: process (clk)
    begin
        if (rising_edge(clk)) then
            if (reset_n = '0') then
                fifo_r_valid    <= '0';
            else        
                fifo_r_valid    <= fifo_en_r;
            end if;
        end if;
    end process FIFO_READ_VALID;
    
    SAVE_MESSAGE_RECEIVED: process (clk)
    begin
        if (rising_edge(clk) and reset_n = '1' and count <= MAX_CYCLES) then
            if (pe_out_valid = '1') then
                last_pe_message_received <= pe_out;
            end if;
        end if;
    end process SAVE_MESSAGE_RECEIVED;
    
    PRINT_MESSAGE_RECEIVED: process (clk)
    variable my_line : line;
    begin
        if (rising_edge(clk) and reset_n = '1' and count <= MAX_CYCLES) then
            write(my_line, string'("Cycle count = "));
            write(my_line, count);
            writeline(output, my_line);
        
            if (x_message_r_valid = '1') then
                write(my_line, string'("x_in: destination = ("));
                write(my_line, to_integer(unsigned(x_message_r((COORD_BITS-1) downto 0))));
                write(my_line, string'(", "));
                write(my_line, to_integer(unsigned(x_message_r((2*COORD_BITS-1) downto COORD_BITS))));
                write(my_line, string'("), data = "));
                write(my_line, x_message_r((BUS_WIDTH-1) downto 2*COORD_BITS));
                write(my_line, string'(", raw = "));
                write(my_line, x_message_r((BUS_WIDTH-1) downto 0));
                
                writeline(output, my_line);
            end if;
            
            if (y_message_r_valid = '1') then
                write(my_line, string'("y_in: destination = ("));
                write(my_line, to_integer(unsigned(y_message_r((COORD_BITS-1) downto 0))));
                write(my_line, string'(", "));
                write(my_line, to_integer(unsigned(y_message_r((2*COORD_BITS-1) downto COORD_BITS))));
                write(my_line, string'("), data = "));
                write(my_line, y_message_r((BUS_WIDTH-1) downto 2*COORD_BITS));
                write(my_line, string'(", raw = "));
                write(my_line, y_message_r((BUS_WIDTH-1) downto 0));
                
                writeline(output, my_line);
            end if;
            
            if (x_out_valid = '1') then
                write(my_line, string'("x_out: destination = ("));
                write(my_line, to_integer(unsigned(x_out((COORD_BITS-1) downto 0))));
                write(my_line, string'(", "));
                write(my_line, to_integer(unsigned(x_out((2*COORD_BITS-1) downto COORD_BITS))));
                write(my_line, string'("), data = "));
                write(my_line, x_out((BUS_WIDTH-1) downto 2*COORD_BITS));
                write(my_line, string'(", raw = "));
                write(my_line, x_out((BUS_WIDTH-1) downto 0));
                
                writeline(output, my_line);
            end if;
            
            if (y_out_valid = '1') then
                write(my_line, string'("y_out: destination = ("));
                write(my_line, to_integer(unsigned(y_out((COORD_BITS-1) downto 0))));
                write(my_line, string'(", "));
                write(my_line, to_integer(unsigned(y_out((2*COORD_BITS-1) downto COORD_BITS))));
                write(my_line, string'("), data = "));
                write(my_line, y_out((BUS_WIDTH-1) downto 2*COORD_BITS));
                write(my_line, string'(", raw = "));
                write(my_line, y_out((BUS_WIDTH-1) downto 0));
                
                writeline(output, my_line);
            end if;
            
            if (pe_out_valid = '1') then
                write(my_line, string'("pe_out: destination = ("));
                write(my_line, to_integer(unsigned(pe_out((COORD_BITS-1) downto 0))));
                write(my_line, string'(", "));
                write(my_line, to_integer(unsigned(pe_out((2*COORD_BITS-1) downto COORD_BITS))));
                write(my_line, string'("), data = "));
                write(my_line, pe_out((BUS_WIDTH-1) downto 2*COORD_BITS));
                write(my_line, string'(", raw = "));
                write(my_line, pe_out((BUS_WIDTH-1) downto 0));
                
                writeline(output, my_line);
            end if;
            
            if (fifo_r_valid = '1') then
                write(my_line, string'("fifo_out: destination = ("));
                write(my_line, to_integer(unsigned(fifo_data_r((COORD_BITS-1) downto 0))));
                write(my_line, string'(", "));
                write(my_line, to_integer(unsigned(fifo_data_r((2*COORD_BITS-1) downto COORD_BITS))));
                write(my_line, string'("), data = "));
                write(my_line, fifo_data_r((BUS_WIDTH-1) downto 2*COORD_BITS));
                write(my_line, string'(", raw = "));
                write(my_line, fifo_data_r((BUS_WIDTH-1) downto 0));
                
                writeline(output, my_line);
            end if;
            
            -- Print a new line
            write(my_line, string'(""));
            writeline(output, my_line);
        end if;
    end process PRINT_MESSAGE_RECEIVED;
    
    CHECK_MESSAGE: process (clk)
    variable my_line : line;
    begin
        if (rising_edge(clk) and reset_n = '1' and count <= MAX_CYCLES) then
            if (fifo_r_valid = '1') then
                if (unsigned(fifo_data_r) /= unsigned(last_pe_message_received)) then
                    write(my_line, string'("Message "));
                    write(my_line, count-1);
                    write(my_line, string'(" does not match"));
                    writeline(output, my_line);
                    
                    write(my_line, string'("pe_out: destination = ("));
                    write(my_line, to_integer(unsigned(pe_out((COORD_BITS-1) downto 0))));
                    write(my_line, string'(", "));
                    write(my_line, to_integer(unsigned(pe_out((2*COORD_BITS-1) downto COORD_BITS))));
                    write(my_line, string'("), data = "));
                    write(my_line, pe_out((BUS_WIDTH-1) downto 2*COORD_BITS));
                    write(my_line, string'(", raw = "));
                    write(my_line, pe_out((BUS_WIDTH-1) downto 0));
                    
                    writeline(output, my_line);
                    
                    write(my_line, string'("fifo_out: destination = ("));
                    write(my_line, to_integer(unsigned(fifo_data_r((COORD_BITS-1) downto 0))));
                    write(my_line, string'(", "));
                    write(my_line, to_integer(unsigned(fifo_data_r((2*COORD_BITS-1) downto COORD_BITS))));
                    write(my_line, string'("), data = "));
                    write(my_line, fifo_data_r((BUS_WIDTH-1) downto 2*COORD_BITS));
                    write(my_line, string'(", raw = "));
                    write(my_line, fifo_data_r((BUS_WIDTH-1) downto 0));
                    
                    writeline(output, my_line);
                    
                    -- Print a new line
                    write(my_line, string'(""));
                    writeline(output, my_line);
                    
                    finish;
                else
                    write(my_line, string'("Message "));
                    write(my_line, count-1);
                    write(my_line, string'(" matches"));
                    writeline(output, my_line);
                    
                    -- Print a new line
                    write(my_line, string'(""));
                    writeline(output, my_line);
                end if;
            end if;
        end if;
    end process CHECK_MESSAGE;

end Behavioral;
