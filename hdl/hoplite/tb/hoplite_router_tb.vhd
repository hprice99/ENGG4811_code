library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.math_real.all;

use STD.textio.all;
use IEEE.std_logic_textio.all;

library xil_defaultlib;
use xil_defaultlib.random.all;
use xil_defaultlib.math_functions.all;

use std.env.finish;
use std.env.stop;

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

    component nic_testbench
        generic (
            BUS_WIDTH   : integer := 32;
            FIFO_DEPTH  : integer := 64
        );
        port (
            clk                 : in std_logic;
            reset_n             : in std_logic;

            pe_in_valid         : in std_logic;
            pe_in_data          : in std_logic_vector((BUS_WIDTH-1) downto 0);

            network_ready       : in std_logic;

            network_out_valid   : out std_logic;
            network_out_data    : out std_logic_vector((BUS_WIDTH-1) downto 0);

            full           : out std_logic;
            empty          : out std_logic
        );
    end component nic_testbench;
    
    signal clk          : std_logic := '0';
    constant clk_period : time := 10 ns;
    
    signal reset_n      : std_logic;

    constant MAX_CYCLES         : integer := 500;
    constant VALID_THRESHOLD    : real := 0.75;
    constant PE_IN_THRESHOLD    : real := 0.10;
    
    constant X_COORD    : integer := 0;
    constant Y_COORD    : integer := 0;
    constant COORD_BITS : integer := 2;
    constant BUS_WIDTH  : integer := 4 * COORD_BITS;
    constant DATA_WIDTH : integer := BUS_WIDTH - 2*COORD_BITS;
    
    constant NETWORK_ROWS   : integer := 2 ** COORD_BITS;
    constant NETWORK_COLS   : integer := 2 ** COORD_BITS;
    constant NETWORK_NODES  : integer := NETWORK_ROWS * NETWORK_COLS;
    
    signal count        : integer;
    
    constant X_INDEX    : integer := 0;
    constant Y_INDEX    : integer := 1;

    type t_Coordinate is array (0 to 1) of std_logic_vector((COORD_BITS-1) downto 0);
    signal x_message_dest, y_message_dest, pe_message_dest : t_Coordinate;
    
    signal x_message_data, y_message_data, pe_message_data : std_logic_vector((DATA_WIDTH-1) downto 0);
    
    signal x_message_b, y_message_b, pe_message_b                   : std_logic_vector((BUS_WIDTH-1) downto 0);
    signal x_message_b_valid, y_message_b_valid, pe_message_b_valid : std_logic;
    
    signal x_message_r, y_message_r, pe_message_r                   : std_logic_vector((BUS_WIDTH-1) downto 0);
    signal x_message_r_valid, y_message_r_valid, pe_message_r_valid : std_logic;
    
    signal x_in        : std_logic_vector((BUS_WIDTH-1) downto 0);
    signal x_in_valid  : std_logic;
    
    signal y_in        : std_logic_vector((BUS_WIDTH-1) downto 0);
    signal y_in_valid  : std_logic;
    
    signal pe_in           : std_logic_vector((BUS_WIDTH-1) downto 0);
    signal pe_in_valid     : std_logic;
    
    signal x_out        : std_logic_vector((BUS_WIDTH-1) downto 0);
    signal x_out_valid  : std_logic;
    
    signal y_out        : std_logic_vector((BUS_WIDTH-1) downto 0);
    signal y_out_valid  : std_logic;
    
    signal pe_out           :    std_logic_vector((BUS_WIDTH-1) downto 0);
    signal pe_out_valid         : std_logic;
    signal pe_backpressure      : std_logic;
    signal not_pe_backpressure  : std_logic;
    
    constant FIFO_ADDRESS_WIDTH     : natural := ceil_log2(MAX_CYCLES);
    constant FIFO_DEPTH             : natural := 2 ** FIFO_ADDRESS_WIDTH;
    constant FIFO_DATA_WIDTH        : natural := BUS_WIDTH; 
        
    signal check_dest_fifo_en_w, check_dest_fifo_en_r       : std_logic;
    signal check_dest_fifo_empty, check_dest_fifo_full      : std_logic;
    signal check_dest_fifo_data_w, check_dest_fifo_data_r   : std_logic_vector((BUS_WIDTH-1) downto 0);
    
    signal check_pe_message_fifo_en_w, check_pe_message_fifo_en_r       : std_logic;
    signal check_pe_message_fifo_empty, check_pe_message_fifo_full      : std_logic;
    signal check_pe_message_fifo_data_w, check_pe_message_fifo_data_r   : std_logic_vector((BUS_WIDTH-1) downto 0);
    
    constant PRINT_X_IN         : boolean := true;
    constant PRINT_Y_IN         : boolean := true;
    constant PRINT_PE_IN        : boolean := true;
    constant PRINT_PE_FIFO_IN   : boolean := true;
    
    constant PRINT_X_OUT            : boolean := true;
    constant PRINT_Y_OUT            : boolean := true;
    constant PRINT_PE_OUT           : boolean := true;
    constant PRINT_CHECK_FIFO_OUT   : boolean := true;
    
begin

    -- Generate clk and reset_n
    reset_n <= '0', '1' after clk_period;
    
    CLK_PROCESS: process
    begin
        clk <= '0';
        wait for clk_period/2;
        clk <= '1';
        wait for clk_period/2;
    end process CLK_PROCESS;
    
    -- Counter
    COUNTER: process(clk)
        variable my_line : line;
    begin
        if (rising_edge(clk)) then
            if (reset_n = '0') then
                count   <= 0;
            else
                count   <= count + 1;

                if (count = MAX_CYCLES) then
                    write(my_line, string'(CR & LF & "SUCCESS - Test complete"));       
                    writeline(output, my_line);
                    stop;
                end if;
            end if;
        end if;
    end process COUNTER;
    
    -- Construct message
    CONSTRUCT_MESSAGE: process (clk)
    begin
        if (rising_edge(clk) and count <= MAX_CYCLES) then
            if (reset_n = '0') then                
                x_message_dest(X_INDEX)     <= (others => '0');
                x_message_dest(Y_INDEX)     <= (others => '0');
                x_message_data              <= (others => '0');
                x_message_b_valid           <= '0';

                y_message_dest(X_INDEX)     <= (others => '0');
                y_message_dest(Y_INDEX)     <= (others => '0');
                y_message_data              <= (others => '0');
                y_message_b_valid           <= '0';
                
                pe_message_dest(X_INDEX)    <= (others => '0');
                pe_message_dest(Y_INDEX)    <= (others => '0');
                pe_message_data             <= (others => '0');
                pe_message_b_valid          <= '0';
            else
                x_message_dest(X_INDEX)     <= rand_slv(COORD_BITS, count);
                x_message_dest(Y_INDEX)     <= rand_slv(COORD_BITS, 2*count);
                x_message_data              <= rand_slv(DATA_WIDTH, 3*count);
                x_message_b_valid           <= rand_logic(VALID_THRESHOLD, count);
                
                -- Incoming Y messages are already in the correct column
                y_message_dest(X_INDEX)     <= "00";
                y_message_dest(Y_INDEX)     <= rand_slv(COORD_BITS, 2*MAX_CYCLES-count);
                y_message_data              <= rand_slv(DATA_WIDTH, 3*MAX_CYCLES-count);
                y_message_b_valid           <= rand_logic(VALID_THRESHOLD, MAX_CYCLES-count);
                
                -- Test a PE message where the destination is the same as the source
                if (count <= 10) then
                    pe_message_dest(X_INDEX)    <= "00";
                    pe_message_dest(Y_INDEX)    <= "00";
                    pe_message_b_valid          <= rand_logic(0.75, count + NETWORK_NODES);
                else
                    pe_message_dest(X_INDEX)    <= rand_slv(COORD_BITS, count + NETWORK_NODES);
                    pe_message_dest(Y_INDEX)    <= rand_slv(COORD_BITS, 2*count + NETWORK_NODES);
                    pe_message_b_valid          <= rand_logic(PE_IN_THRESHOLD, count + NETWORK_NODES);
                end if;
                pe_message_data             <= rand_slv(DATA_WIDTH, 3*count + NETWORK_NODES);
            end if;
        end if;
    end process CONSTRUCT_MESSAGE;
    
    -- Packet format LSB x_dest|y_dest|data MSB                    
    x_message_b     <= x_message_data & x_message_dest(Y_INDEX) & x_message_dest(X_INDEX);
    y_message_b     <= y_message_data & y_message_dest(Y_INDEX) & y_message_dest(X_INDEX);
    pe_message_b    <= pe_message_data & pe_message_dest(Y_INDEX) & pe_message_dest(X_INDEX);
    
    MESSAGE_FF: process (clk)
    begin
        if (rising_edge(clk) and count <= MAX_CYCLES) then
            if (reset_n = '0') then
                x_message_r         <= (others => '0');
                x_message_r_valid   <= '0';
                
                y_message_r         <= (others => '0');
                y_message_r_valid   <= '0';
                
                pe_message_r        <= (others => '0');
                pe_message_r_valid  <= '0';
            else
                x_message_r         <= x_message_b;
                x_message_r_valid   <= x_message_b_valid;
                
                y_message_r         <= y_message_b;
                y_message_r_valid   <= y_message_b_valid;
                
                pe_message_r        <= pe_message_b;
                pe_message_r_valid  <= pe_message_b_valid;
            end if;
        end if;
    end process MESSAGE_FF;
    
    x_in        <= x_message_r;
    x_in_valid  <= x_message_r_valid;
    
    y_in        <= y_message_r;
    y_in_valid  <= y_message_r_valid;
    
    -- Processing element network interface controller
    not_pe_backpressure <= not pe_backpressure;

    PE_NIC: nic_testbench
    generic map (
        BUS_WIDTH   => BUS_WIDTH,
        FIFO_DEPTH  => FIFO_DEPTH
    )
    port map (
        clk                 => clk,
        reset_n             => reset_n,

        pe_in_valid         => pe_message_b_valid,
        pe_in_data          => pe_message_b,

        network_ready       => not_pe_backpressure,

        network_out_valid   => pe_in_valid,
        network_out_data    => pe_in,

        full                => open,
        empty               => open
    );
    
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
        x_in                => x_in,
        x_in_valid          => x_in_valid,
        y_in                => y_in,
        y_in_valid          => y_in_valid,
        pe_in               => pe_in,
        pe_in_valid         => pe_in_valid,
        x_out               => x_out,
        x_out_valid         => x_out_valid,
        y_out               => y_out,
        y_out_valid         => y_out_valid,
        pe_out              => pe_out,
        pe_out_valid        => pe_out_valid,
        pe_backpressure     => pe_backpressure
    );
    
    -- FIFO for checking output messages    
    CHECK_DEST_FIFO: fifo_sync
    generic map (
        BUS_WIDTH   => FIFO_DATA_WIDTH,
        FIFO_DEPTH  => FIFO_DEPTH
    )
    port map (        
        clk         => clk,
        reset_n     => reset_n,
        
        write_en    => check_dest_fifo_en_w,
        write_data  => check_dest_fifo_data_w,

        read_en     => check_dest_fifo_en_r,
        read_data   => check_dest_fifo_data_r,
        
        full        => check_dest_fifo_full,
        empty       => check_dest_fifo_empty
    );
    
    -- Writing to FIFO
    CHECK_DEST_FIFO_WRITE: process (clk)
    begin
        if (rising_edge(clk) and count <= MAX_CYCLES) then
            if (reset_n = '0') then
                check_dest_fifo_data_w <= (others => '0');
                check_dest_fifo_en_w   <= '0';
            elsif (check_dest_fifo_full = '0') then
                 if (x_message_b_valid = '1' and 
                        to_integer(unsigned(x_message_dest(X_INDEX))) = X_COORD and 
                        to_integer(unsigned(x_message_dest(Y_INDEX))) = Y_COORD) then
                    check_dest_fifo_data_w     <= x_message_b;
                    check_dest_fifo_en_w       <= '1';
                 elsif (y_message_b_valid = '1' and 
                            to_integer(unsigned(y_message_dest(X_INDEX))) = X_COORD and 
                            to_integer(unsigned(y_message_dest(Y_INDEX))) = Y_COORD) then
                    check_dest_fifo_data_w     <= y_message_b;
                    check_dest_fifo_en_w       <= '1';
                 else
                    check_dest_fifo_en_w       <= '0';
                 end if;
            end if;
        end if;
    end process CHECK_DEST_FIFO_WRITE;
    
    -- Read from FIFO
    CHECK_DEST_FIFO_READ_ENABLE: process (check_dest_fifo_empty, pe_out_valid)
    begin
        if (check_dest_fifo_empty = '0') then
            check_dest_fifo_en_r   <= pe_out_valid;
        else
            check_dest_fifo_en_r   <= '0';
        end if;
    end process CHECK_DEST_FIFO_READ_ENABLE;
    
    -- FIFO for checking messages sent from processing element
    CHECK_PE_MESSAGE_FIFO: fifo_sync
    generic map (
        BUS_WIDTH   => FIFO_DATA_WIDTH,
        FIFO_DEPTH  => FIFO_DEPTH
    )
    port map (       
        clk         => clk,
        reset_n     => reset_n,
        
        write_en    => check_pe_message_fifo_en_w,
        write_data  => check_pe_message_fifo_data_w,

        read_en     => check_pe_message_fifo_en_r,
        read_data   => check_pe_message_fifo_data_r,
        
        full        => check_pe_message_fifo_full,
        empty       => check_pe_message_fifo_empty
    );
    
    -- Writing to FIFO
    CHECK_PE_MESSAGE_FIFO_WRITE: process (clk)
    begin
        if (rising_edge(clk) and count <= MAX_CYCLES) then
            if (reset_n = '0') then
                check_pe_message_fifo_data_w <= (others => '0');
                check_pe_message_fifo_en_w   <= '0';
            elsif (check_pe_message_fifo_full = '0') then
                if (pe_message_b_valid = '1') then
                    check_pe_message_fifo_data_w     <= pe_message_b;
                    check_pe_message_fifo_en_w       <= '1';
                else
                    check_pe_message_fifo_en_w       <= '0';
                end if;
            end if;
        end if;
    end process CHECK_PE_MESSAGE_FIFO_WRITE;
    
    -- Read from FIFO
    CHECK_PE_MESSAGE_FIFO_READ_ENABLE: process (check_pe_message_fifo_empty, pe_in_valid)
    begin
        if (check_pe_message_fifo_empty = '0') then
            check_pe_message_fifo_en_r   <= pe_in_valid;
        else
            check_pe_message_fifo_en_r   <= '0';
        end if;
    end process CHECK_PE_MESSAGE_FIFO_READ_ENABLE;
    
    -- Check messages received   
    PRINT_MESSAGE_RECEIVED: process (clk)
    variable my_line : line;
    begin
        if (rising_edge(clk) and reset_n = '1' and count <= MAX_CYCLES) then
            write(my_line, string'("Cycle count = "));
            write(my_line, count);
            writeline(output, my_line);
        
            if (x_in_valid = '1' and PRINT_X_IN) then
                write(my_line, string'("x_in: destination = ("));
                write(my_line, to_integer(unsigned(x_in((COORD_BITS-1) downto 0))));
                write(my_line, string'(", "));
                write(my_line, to_integer(unsigned(x_in((2*COORD_BITS-1) downto COORD_BITS))));
                write(my_line, string'("), data = "));
                write(my_line, x_in((BUS_WIDTH-1) downto 2*COORD_BITS));
                write(my_line, string'(", raw = "));
                write(my_line, x_in((BUS_WIDTH-1) downto 0));
                
                writeline(output, my_line);
            end if;
            
            if (y_in_valid = '1' and PRINT_Y_IN) then
                write(my_line, string'("y_in: destination = ("));
                write(my_line, to_integer(unsigned(y_in((COORD_BITS-1) downto 0))));
                write(my_line, string'(", "));
                write(my_line, to_integer(unsigned(y_in((2*COORD_BITS-1) downto COORD_BITS))));
                write(my_line, string'("), data = "));
                write(my_line, y_in((BUS_WIDTH-1) downto 2*COORD_BITS));
                write(my_line, string'(", raw = "));
                write(my_line, y_in((BUS_WIDTH-1) downto 0));
                
                writeline(output, my_line);
            end if;
            
            if (pe_message_r_valid = '1' and PRINT_PE_IN) then
                if (pe_backpressure = '1') then
                    write(my_line, string'("BACKPRESSURE - "));
                end if;
                write(my_line, string'("pe_in: destination = ("));
                write(my_line, to_integer(unsigned(pe_message_r((COORD_BITS-1) downto 0))));
                write(my_line, string'(", "));
                write(my_line, to_integer(unsigned(pe_message_r((2*COORD_BITS-1) downto COORD_BITS))));
                write(my_line, string'("), data = "));
                write(my_line, pe_message_r((BUS_WIDTH-1) downto 2*COORD_BITS));
                write(my_line, string'(", raw = "));
                write(my_line, pe_message_r((BUS_WIDTH-1) downto 0));
                
                writeline(output, my_line);
            end if;
            
            if (pe_in_valid = '1' and PRINT_PE_FIFO_IN) then
                write(my_line, string'("fifo_pe_in: destination = ("));
                write(my_line, to_integer(unsigned(pe_in((COORD_BITS-1) downto 0))));
                write(my_line, string'(", "));
                write(my_line, to_integer(unsigned(pe_in((2*COORD_BITS-1) downto COORD_BITS))));
                write(my_line, string'("), data = "));
                write(my_line, pe_in((BUS_WIDTH-1) downto 2*COORD_BITS));
                write(my_line, string'(", raw = "));
                write(my_line, pe_in((BUS_WIDTH-1) downto 0));
                
                writeline(output, my_line);
            end if;
            
            if (x_out_valid = '1' and PRINT_X_OUT) then
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
            
            if (y_out_valid = '1' and PRINT_Y_OUT) then
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
            
            if (pe_out_valid = '1' and PRINT_PE_OUT) then
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
            
            if (check_dest_fifo_en_r = '1' and PRINT_CHECK_FIFO_OUT) then
                write(my_line, string'("check_dest_fifo_out: destination = ("));
                write(my_line, to_integer(unsigned(check_dest_fifo_data_r((COORD_BITS-1) downto 0))));
                write(my_line, string'(", "));
                write(my_line, to_integer(unsigned(check_dest_fifo_data_r((2*COORD_BITS-1) downto COORD_BITS))));
                write(my_line, string'("), data = "));
                write(my_line, check_dest_fifo_data_r((BUS_WIDTH-1) downto 2*COORD_BITS));
                write(my_line, string'(", raw = "));
                write(my_line, check_dest_fifo_data_r((BUS_WIDTH-1) downto 0));
                
                writeline(output, my_line);
            end if;
            
            -- Print a new line
            write(my_line, string'(""));
            writeline(output, my_line);
        end if;
    end process PRINT_MESSAGE_RECEIVED;
    
    CHECK_DEST_MESSAGE: process (clk)
    variable my_line : line;
    begin
        if (rising_edge(clk) and reset_n = '1' and count <= MAX_CYCLES) then
            if (check_dest_fifo_en_r = '1') then
                if (unsigned(check_dest_fifo_data_r) /= unsigned(pe_out)) then
                    write(my_line, string'(HT & "pe_out message "));
                    write(my_line, count-1);
                    write(my_line, string'(" does not match"));
                    writeline(output, my_line);
                    
                    write(my_line, string'(HT & "pe_out: destination = ("));
                    write(my_line, to_integer(unsigned(pe_out((COORD_BITS-1) downto 0))));
                    write(my_line, string'(", "));
                    write(my_line, to_integer(unsigned(pe_out((2*COORD_BITS-1) downto COORD_BITS))));
                    write(my_line, string'("), data = "));
                    write(my_line, pe_out((BUS_WIDTH-1) downto 2*COORD_BITS));
                    write(my_line, string'(", raw = "));
                    write(my_line, pe_out((BUS_WIDTH-1) downto 0));
                    
                    writeline(output, my_line);
                    
                    write(my_line, string'(HT & "check_dest_fifo_out: destination = ("));
                    write(my_line, to_integer(unsigned(check_dest_fifo_data_r((COORD_BITS-1) downto 0))));
                    write(my_line, string'(", "));
                    write(my_line, to_integer(unsigned(check_dest_fifo_data_r((2*COORD_BITS-1) downto COORD_BITS))));
                    write(my_line, string'("), data = "));
                    write(my_line, check_dest_fifo_data_r((BUS_WIDTH-1) downto 2*COORD_BITS));
                    write(my_line, string'(", raw = "));
                    write(my_line, check_dest_fifo_data_r((BUS_WIDTH-1) downto 0));
                    
                    writeline(output, my_line);
                    
                    -- Print a new line
                    write(my_line, string'(""));
                    writeline(output, my_line);
                    
                    finish;
                else
                    write(my_line, string'(HT & "pe_out message "));
                    write(my_line, count-1);
                    write(my_line, string'(" matches"));
                    writeline(output, my_line);
                    
                    -- Print a new line
                    write(my_line, string'(""));
                    writeline(output, my_line);
                end if;
            end if;
        end if;
    end process CHECK_DEST_MESSAGE;
    
    -- Check messages sent from processing element   
    CHECK_PE_MESSAGE: process (clk)
    variable my_line : line;
    begin
        if (rising_edge(clk) and reset_n = '1' and count <= MAX_CYCLES) then
            if (check_pe_message_fifo_en_r = '1') then
                if (unsigned(check_pe_message_fifo_data_r) /= unsigned(pe_in)) then
                    write(my_line, string'(HT & "pe_in message "));
                    write(my_line, count-1);
                    write(my_line, string'(" does not match"));
                    writeline(output, my_line);
                    
                    write(my_line, string'(HT & "check_pe_message_fifo_data_r: destination = ("));
                    write(my_line, to_integer(unsigned(check_pe_message_fifo_data_r((COORD_BITS-1) downto 0))));
                    write(my_line, string'(", "));
                    write(my_line, to_integer(unsigned(check_pe_message_fifo_data_r((2*COORD_BITS-1) downto COORD_BITS))));
                    write(my_line, string'("), data = "));
                    write(my_line, check_pe_message_fifo_data_r((BUS_WIDTH-1) downto 2*COORD_BITS));
                    write(my_line, string'(", raw = "));
                    write(my_line, check_pe_message_fifo_data_r((BUS_WIDTH-1) downto 0));
                    
                    writeline(output, my_line);
                    
                    write(my_line, string'(HT & "pe_in: destination = ("));
                    write(my_line, to_integer(unsigned(pe_in((COORD_BITS-1) downto 0))));
                    write(my_line, string'(", "));
                    write(my_line, to_integer(unsigned(pe_in((2*COORD_BITS-1) downto COORD_BITS))));
                    write(my_line, string'("), data = "));
                    write(my_line, pe_in((BUS_WIDTH-1) downto 2*COORD_BITS));
                    write(my_line, string'(", raw = "));
                    write(my_line, pe_in((BUS_WIDTH-1) downto 0));
                    
                    writeline(output, my_line);
                    
                    -- Print a new line
                    write(my_line, string'(""));
                    writeline(output, my_line);
                    
                    -- finish;
                    stop;
                else
                    write(my_line, string'(HT & "pe_in message "));
                    write(my_line, count-1);
                    write(my_line, string'(" matches"));
                    writeline(output, my_line);
                    
                    write(my_line, string'(HT & "check_pe_message_fifo_data_r: destination = ("));
                    write(my_line, to_integer(unsigned(check_pe_message_fifo_data_r((COORD_BITS-1) downto 0))));
                    write(my_line, string'(", "));
                    write(my_line, to_integer(unsigned(check_pe_message_fifo_data_r((2*COORD_BITS-1) downto COORD_BITS))));
                    write(my_line, string'("), data = "));
                    write(my_line, check_pe_message_fifo_data_r((BUS_WIDTH-1) downto 2*COORD_BITS));
                    write(my_line, string'(", raw = "));
                    write(my_line, check_pe_message_fifo_data_r((BUS_WIDTH-1) downto 0));
                    
                    writeline(output, my_line);
                    
                    write(my_line, string'(HT & "pe_in: destination = ("));
                    write(my_line, to_integer(unsigned(pe_in((COORD_BITS-1) downto 0))));
                    write(my_line, string'(", "));
                    write(my_line, to_integer(unsigned(pe_in((2*COORD_BITS-1) downto COORD_BITS))));
                    write(my_line, string'("), data = "));
                    write(my_line, pe_in((BUS_WIDTH-1) downto 2*COORD_BITS));
                    write(my_line, string'(", raw = "));
                    write(my_line, pe_in((BUS_WIDTH-1) downto 0));
                    
                    -- Print a new line
                    write(my_line, string'(""));
                    writeline(output, my_line);
                    write(my_line, string'(""));
                    writeline(output, my_line);
                end if;
            end if;
        end if;
    end process CHECK_PE_MESSAGE;

end Behavioral;
