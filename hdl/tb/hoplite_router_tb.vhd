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

use STD.textio.all;
use IEEE.std_logic_textio.all;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

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
    
    constant MAX_CYCLES : integer := 10;
    
    constant X_COORD    : integer := 0;
    constant Y_COORD    : integer := 0;
    constant COORD_BITS : integer := 2;
    constant BUS_WIDTH  : integer := 4 * COORD_BITS;
    
    constant X_SRC      : std_logic_vector((COORD_BITS-1) downto 0) := std_logic_vector(to_unsigned(X_COORD, COORD_BITS));
    constant Y_SRC      : std_logic_vector((COORD_BITS-1) downto 0) := std_logic_vector(to_unsigned(X_COORD, COORD_BITS));
    constant X_DEST     : std_logic_vector((COORD_BITS-1) downto 0) := "01";
    constant Y_DEST     : std_logic_vector((COORD_BITS-1) downto 0) := "01";
    
    constant NETWORK_ROWS : integer := 3;
    constant NETWORK_COLS : integer := 3;
    
    signal count        : integer;
    signal x_data_count : integer;
    signal y_data_count : integer;
    signal x_dest_count : integer;
    signal y_dest_count : integer;
    
    signal message_b                            : std_logic_vector((BUS_WIDTH-1) downto 0);
    signal x_message_b, y_message_b             : std_logic_vector((BUS_WIDTH-1) downto 0);
    signal message_x_r, message_y_r             : std_logic_vector((BUS_WIDTH-1) downto 0);
    signal message_x_r_valid, message_y_r_valid : std_logic;
    
    signal x_out : std_logic_vector((BUS_WIDTH-1) downto 0);
    signal x_out_valid : std_logic;
    
    signal y_out : std_logic_vector((BUS_WIDTH-1) downto 0);
    signal y_out_valid : std_logic;
    
    signal pe_out : std_logic_vector((BUS_WIDTH-1) downto 0);
    signal pe_out_valid : std_logic;
    
    signal clk          : std_logic := '0';
    constant clk_period : time := 10 ns;
    
    signal reset_n      : std_logic;

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
                x_dest_count <= 0;
                y_dest_count <= 0;
            else
                count <= count + 1;
                x_dest_count <= (x_dest_count + 1) mod NETWORK_ROWS;
                y_dest_count <= (y_dest_count + 2) mod NETWORK_COLS;
            end if;
        end if;
    end process CONSTRUCT_MESSAGE;
    
    x_data_count <= 0;
    y_data_count <= 1;
    
    -- Packet format LSB x_dest|y_dest|data MSB
--    message_b <= std_logic_vector(to_unsigned(count, 2*COORD_BITS)) & Y_DEST & X_DEST;
    message_b <= std_logic_vector(to_unsigned(count, 2*COORD_BITS)) & 
                    std_logic_vector(to_unsigned(y_dest_count, COORD_BITS)) & 
                    std_logic_vector(to_unsigned(x_dest_count, COORD_BITS));
                    
    x_message_b <= std_logic_vector(to_unsigned(x_data_count, 2*COORD_BITS)) & 
                    std_logic_vector(to_unsigned(y_dest_count, COORD_BITS)) & 
                    std_logic_vector(to_unsigned(x_dest_count, COORD_BITS));

    y_message_b <= std_logic_vector(to_unsigned(y_data_count, 2*COORD_BITS)) & 
                    std_logic_vector(to_unsigned((y_dest_count + 2) mod NETWORK_COLS, COORD_BITS)) & 
                    std_logic_vector(to_unsigned((x_dest_count + 1) mod NETWORK_ROWS, COORD_BITS));
    
    MESSAGE_FF: process (clk)
    begin
        if (rising_edge(clk) and count <= MAX_CYCLES) then
            if (reset_n = '0') then
                message_x_r <= (others => '0');
                message_x_r_valid <= '0';
                
                message_y_r <= (others => '0');
                message_y_r_valid <= '0';
            else
                -- message_y_r <= message_x_r;
                message_y_r <= y_message_b;
                message_y_r_valid <= message_x_r_valid;
            
                -- message_x_r <= message_b;
                message_x_r <= x_message_b;
                message_x_r_valid <= '1';
            end if;
        end if;
    end process MESSAGE_FF;
    
    ROUTER: hoplite_router
    generic map (
        BUS_WIDTH   => BUS_WIDTH,
        X_COORD     => X_COORD,
        Y_COORD     => Y_COORD,
        COORD_BITS  => COORD_BITS
    )
    port map (
        clk                 => clk,
        reset_n             => reset_n,
        x_in                => message_x_r,
        x_in_valid          => message_x_r_valid,
        y_in                => message_y_r,
        y_in_valid          => message_y_r_valid,
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
    
    MESSAGE_RECEIVED: process (clk)
    variable my_line : line;
    begin
        if (rising_edge(clk) and reset_n = '1' and count <= MAX_CYCLES) then
            write(my_line, string'("Cycle count = "));
            write(my_line, count);
            writeline(output, my_line);
        
            if (message_x_r_valid = '1') then
                write(my_line, string'("x_in: destination = ("));
                write(my_line, to_integer(unsigned(message_x_r((COORD_BITS-1) downto 0))));
                write(my_line, string'(", "));
                write(my_line, to_integer(unsigned(message_x_r((2*COORD_BITS-1) downto COORD_BITS))));
                write(my_line, string'("), data = "));
                write(my_line, message_x_r((BUS_WIDTH-1) downto 2*COORD_BITS));
                write(my_line, string'(", raw = "));
                write(my_line, message_x_r((BUS_WIDTH-1) downto 0));
                
                writeline(output, my_line);
            end if;
            
            if (message_y_r_valid = '1') then
                write(my_line, string'("y_in: destination = ("));
                write(my_line, to_integer(unsigned(message_y_r((COORD_BITS-1) downto 0))));
                write(my_line, string'(", "));
                write(my_line, to_integer(unsigned(message_y_r((2*COORD_BITS-1) downto COORD_BITS))));
                write(my_line, string'("), data = "));
                write(my_line, message_y_r((BUS_WIDTH-1) downto 2*COORD_BITS));
                write(my_line, string'(", raw = "));
                write(my_line, message_y_r((BUS_WIDTH-1) downto 0));
                
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
            
            -- Print a new line
            write(my_line, string'(""));
            writeline(output, my_line);
        end if;
    end process MESSAGE_RECEIVED;

end Behavioral;
