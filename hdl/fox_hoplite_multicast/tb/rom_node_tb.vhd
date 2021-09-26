----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 09/15/2021 08:42:06 AM
-- Design Name: 
-- Module Name: rom_node_tb - Behavioral
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
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

use STD.textio.all;
use IEEE.std_logic_textio.all;

use std.env.finish;
use std.env.stop;

library xil_defaultlib;
use xil_defaultlib.packet_defs.all;
use xil_defaultlib.matrix_config.all;
use xil_defaultlib.fox_defs.all;
use xil_defaultlib.math_functions.all;
use xil_defaultlib.conv_functions.all;

entity rom_node_tb is
--  Port ( );
end rom_node_tb;

architecture Behavioral of rom_node_tb is

    component rom_node is
        Generic (   
            -- Node parameters
            X_COORD         : integer := 0;
            Y_COORD         : integer := 0;
            
            -- Multicast parameters
            USE_MULTICAST           : boolean := False;
            MULTICAST_X_COORD       : integer := 1;
            MULTICAST_Y_COORD       : integer := 1;
    
            -- Packet parameters
            COORD_BITS              : integer := 2;
            MULTICAST_GROUP_BITS    : integer := 1;
            MULTICAST_COORD_BITS    : integer := 1;
            MATRIX_TYPE_BITS        : integer := 1;
            MATRIX_COORD_BITS       : integer := 8;
            MATRIX_ELEMENT_BITS     : integer := 32;
            BUS_WIDTH               : integer := 56;
    
            FIFO_DEPTH              : integer := 64;
            
            USE_INITIALISATION_FILE : boolean := True;
            MATRIX_FILE             : string  := "none";
            ROM_DEPTH               : integer := 64;
            ROM_ADDRESS_WIDTH       : integer := 6;
        
            USE_BURST               : boolean := False;
            BURST_LENGTH            : integer := 0
        );
        Port (
            clk                 : in std_logic;
            reset_n             : in std_logic;
    
            rom_read_complete   : out std_logic;
    
            x_in                : in STD_LOGIC_VECTOR((BUS_WIDTH-1) downto 0);
            x_in_valid          : in STD_LOGIC;
            y_in                : in STD_LOGIC_VECTOR((BUS_WIDTH-1) downto 0);
            y_in_valid          : in STD_LOGIC;
            
            x_out               : out STD_LOGIC_VECTOR((BUS_WIDTH-1) downto 0);
            x_out_valid         : out STD_LOGIC;
            y_out               : out STD_LOGIC_VECTOR((BUS_WIDTH-1) downto 0);
            y_out_valid         : out STD_LOGIC
        );
    end component rom_node;
    
    component message_decoder
        generic (
            COORD_BITS              : integer := 2;
            MULTICAST_GROUP_BITS    : integer := 1;
            MULTICAST_COORD_BITS    : integer := 1;
            
            MATRIX_TYPE_BITS        : integer := 1;
            MATRIX_COORD_BITS       : integer := 8;
            MATRIX_ELEMENT_BITS     : integer := 32;
            BUS_WIDTH               : integer := 56
        );
        port (
            clk                 : in std_logic;
            reset_n             : in std_logic;
            
            packet_in           : in std_logic_vector((BUS_WIDTH-1) downto 0);
            packet_in_valid     : in std_logic;
            
            x_coord_out         : out std_logic_vector((COORD_BITS-1) downto 0);
            y_coord_out         : out std_logic_vector((COORD_BITS-1) downto 0);
            multicast_group_out : out std_logic_vector((MULTICAST_GROUP_BITS-1) downto 0);
            done_flag_out       : out std_logic;
            result_flag_out     : out std_logic;
            matrix_type_out     : out std_logic_vector((MATRIX_TYPE_BITS-1) downto 0);
            matrix_x_coord_out  : out std_logic_vector((MATRIX_COORD_BITS-1) downto 0);
            matrix_y_coord_out  : out std_logic_vector((MATRIX_COORD_BITS-1) downto 0);
            matrix_element_out  : out std_logic_vector((MATRIX_ELEMENT_BITS-1) downto 0);

            packet_out_valid    : out std_logic;
            
            packet_read         : in std_logic
        );
    end component message_decoder;
    
    signal clk          : std_logic;
    constant clk_period : time := 10 ns;
    
    signal reset_n  : std_logic;
    
    constant matrix_file        : string := "combined.mif";
    constant matrix_file_length : integer := 2 * TOTAL_MATRIX_ELEMENTS;
    
    constant ADDRESS_WIDTH  : integer := ceil_log2(matrix_file_length);
    
    constant X_COORD    : integer := 0;
    constant Y_COORD    : integer := 2;
    
    constant NIC_FIFO_DEPTH : integer := 16;
    
    constant BURST_LENGTH   : integer := matrix_file_length / 2;
    
    signal rom_read_complete    : std_logic;
    
    signal x_in, y_in   : std_logic_vector((BUS_WIDTH-1) downto 0);
    signal x_in_valid, y_in_valid   : std_logic;
    
    signal x_out, y_out   : std_logic_vector((BUS_WIDTH-1) downto 0);
    signal x_out_valid, y_out_valid   : std_logic;
    
    -- Decoder signals
    signal x_decoder_packet_in        : std_logic_vector((BUS_WIDTH-1) downto 0);
    signal x_decoder_packet_in_valid  : std_logic;
    
    signal x_decoder_x_coord_out          : std_logic_vector((COORD_BITS-1) downto 0);
    signal x_decoder_y_coord_out          : std_logic_vector((COORD_BITS-1) downto 0);
    signal x_decoder_multicast_group_out  : std_logic_vector((MULTICAST_GROUP_BITS-1) downto 0);
    signal x_decoder_done_flag_out        : std_logic;
    signal x_decoder_result_flag_out      : std_logic;
    signal x_decoder_matrix_type_out      : std_logic_vector((MATRIX_TYPE_BITS-1) downto 0);
    signal x_decoder_matrix_x_coord_out   : std_logic_vector((MATRIX_COORD_BITS-1) downto 0);
    signal x_decoder_matrix_y_coord_out   : std_logic_vector((MATRIX_COORD_BITS-1) downto 0);
    signal x_decoder_matrix_element_out   : std_logic_vector((MATRIX_ELEMENT_BITS-1) downto 0);
    
    signal x_decoder_packet_out_valid     : std_logic;
    signal x_decoder_packet_read          : std_logic;
    
    signal y_decoder_packet_in        : std_logic_vector((BUS_WIDTH-1) downto 0);
    signal y_decoder_packet_in_valid  : std_logic;
    
    signal y_decoder_x_coord_out          : std_logic_vector((COORD_BITS-1) downto 0);
    signal y_decoder_y_coord_out          : std_logic_vector((COORD_BITS-1) downto 0);
    signal y_decoder_multicast_group_out  : std_logic_vector((MULTICAST_GROUP_BITS-1) downto 0);
    signal y_decoder_done_flag_out        : std_logic;
    signal y_decoder_result_flag_out      : std_logic;
    signal y_decoder_matrix_type_out      : std_logic_vector((MATRIX_TYPE_BITS-1) downto 0);
    signal y_decoder_matrix_x_coord_out   : std_logic_vector((MATRIX_COORD_BITS-1) downto 0);
    signal y_decoder_matrix_y_coord_out   : std_logic_vector((MATRIX_COORD_BITS-1) downto 0);
    signal y_decoder_matrix_element_out   : std_logic_vector((MATRIX_ELEMENT_BITS-1) downto 0);
    
    signal y_decoder_packet_out_valid     : std_logic;
    signal y_decoder_packet_read          : std_logic;

    signal ready_decoder_packet_in        : std_logic_vector((BUS_WIDTH-1) downto 0);
    signal ready_decoder_packet_in_valid  : std_logic;
    
    signal ready_decoder_x_coord_out          : std_logic_vector((COORD_BITS-1) downto 0);
    signal ready_decoder_y_coord_out          : std_logic_vector((COORD_BITS-1) downto 0);
    signal ready_decoder_multicast_group_out  : std_logic_vector((MULTICAST_GROUP_BITS-1) downto 0);
    signal ready_decoder_done_flag_out        : std_logic;
    signal ready_decoder_result_flag_out      : std_logic;
    signal ready_decoder_matrix_type_out      : std_logic_vector((MATRIX_TYPE_BITS-1) downto 0);
    signal ready_decoder_matrix_x_coord_out   : std_logic_vector((MATRIX_COORD_BITS-1) downto 0);
    signal ready_decoder_matrix_y_coord_out   : std_logic_vector((MATRIX_COORD_BITS-1) downto 0);
    signal ready_decoder_matrix_element_out   : std_logic_vector((MATRIX_ELEMENT_BITS-1) downto 0);
    
    signal ready_decoder_packet_out_valid     : std_logic;
    signal ready_decoder_packet_read          : std_logic;

    impure function print_decoded_message (count            : in integer;
                                           packet           : in std_logic_vector;
                                           x_coord          : in std_logic_vector;
                                           y_coord          : in std_logic_vector;
                                           multicast_group  : in std_logic_vector;
                                           done_flag        : in std_logic;
                                           result_flag      : in std_logic;
                                           matrix_type      : in std_logic_vector;
                                           matrix_x_coord   : in std_logic_vector;
                                           matrix_y_coord   : in std_logic_vector;
                                           matrix_element   : in std_logic_vector) 
            return line is
        variable my_line    : line;
    begin
        write(my_line, string'(HT & HT & "Cycle: "));
        write(my_line, count);
    
        write(my_line, string'(", Encoded packet: "));
        hwrite(my_line, packet);
        
        write(my_line, string'(", decoded packet: "));
        
        write(my_line, string'("dest = ("));
        write(my_line, slv_to_int(x_coord));
        write(my_line, string'(", "));
        write(my_line, slv_to_int(y_coord));
        write(my_line, string'(")"));
        
        write(my_line, string'(", multicast group = "));
        write(my_line, slv_to_int(multicast_group));
        
        write(my_line, string'(", done flag = "));
        write(my_line, done_flag);
        
        write(my_line, string'(", result flag = "));
        write(my_line, result_flag);
        
        write(my_line, string'(", matrix type = "));
        
        if (slv_to_int(matrix_type) = 0) then
            write(my_line, string'("A"));
        elsif (slv_to_int(matrix_type) = 1) then
            write(my_line, string'("B"));
        end if;
        
        write(my_line, string'(", matrix coordinate = ("));
        write(my_line, slv_to_int(matrix_x_coord));
        write(my_line, string'(", "));
        write(my_line, slv_to_int(matrix_y_coord));
        write(my_line, string'(")"));
        
        write(my_line, string'(", matrix element = "));
        write(my_line, slv_to_int(matrix_element));
        
        return my_line;
    end function print_decoded_message;
    
    signal x_packets_received, y_packets_received, total_packets_received   : integer;
        
    signal node_ready_x, node_ready_y   : integer;
    signal ready_packets_sent   : integer;
    
    signal count    : integer;

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
    
    y_in        <= (others => '0');
    y_in_valid  <= '0';

    COUNTER: process (clk)
    begin
        if (rising_edge(clk)) then
            if (reset_n = '0') then
                count   <= 0;
            end if;
        else
            count   <= count + 1;
        end if;
    end process COUNTER;

    -- Generate ready packets to send to the rom_node
    READY_PACKET_PROC: process (clk)
    begin
        if (rising_edge(clk)) then
            if (reset_n = '0') then
                x_in        <= (others => '0');
                x_in_valid  <= '0';
                
                node_ready_x        <= 0;
                node_ready_y        <= 0;
                ready_packets_sent  <= 0;
            
            else 
                if (total_packets_received = 0 and ready_packets_sent < FOX_NETWORK_NODES) then
                    x_in(X_COORD_END downto X_COORD_START)  <= std_logic_vector(to_unsigned(X_COORD, COORD_BITS));
                    x_in(Y_COORD_END downto Y_COORD_START)  <= std_logic_vector(to_unsigned(Y_COORD, COORD_BITS));
                
                    x_in(MATRIX_X_COORD_END downto MATRIX_X_COORD_START)  <= std_logic_vector(to_unsigned(node_ready_x, MATRIX_COORD_BITS));
                    x_in(MATRIX_Y_COORD_END downto MATRIX_Y_COORD_START)  <= std_logic_vector(to_unsigned(node_ready_y, MATRIX_COORD_BITS));
                    x_in(DONE_FLAG_BIT) <= '1';
                    
                    x_in_valid  <= '1';
                    
                    if (node_ready_x < FOX_NETWORK_STAGES-1) then
                        node_ready_x    <= node_ready_x + 1;
                    elsif (node_ready_x = FOX_NETWORK_STAGES-1) then
                        node_ready_x    <= 0;
                    end if;

                    if (node_ready_x = FOX_NETWORK_STAGES-1 and node_ready_y < FOX_NETWORK_STAGES-1) then
                        node_ready_y    <= node_ready_y + 1;
                    end if;
                    
                    ready_packets_sent  <= ready_packets_sent + 1;
                
                elsif (total_packets_received = BURST_LENGTH and ready_packets_sent < 2*FOX_NETWORK_NODES) then
                    x_in(X_COORD_END downto X_COORD_START)  <= std_logic_vector(to_unsigned(X_COORD, COORD_BITS));
                    x_in(Y_COORD_END downto Y_COORD_START)  <= std_logic_vector(to_unsigned(Y_COORD, COORD_BITS));
                
                    x_in(MATRIX_X_COORD_END downto MATRIX_X_COORD_START)  <= std_logic_vector(to_unsigned(node_ready_x, MATRIX_COORD_BITS));
                    x_in(MATRIX_Y_COORD_END downto MATRIX_Y_COORD_START)  <= std_logic_vector(to_unsigned(node_ready_y, MATRIX_COORD_BITS));
                    x_in(DONE_FLAG_BIT) <= '1';
                    
                    x_in_valid  <= '1';
                    
                    if (node_ready_x < FOX_NETWORK_STAGES-1) then
                        node_ready_x    <= node_ready_x + 1;
                    elsif (node_ready_x = FOX_NETWORK_STAGES-1) then
                        node_ready_x    <= 0;
                    end if;

                    if (node_ready_x = FOX_NETWORK_STAGES-1 and node_ready_y < FOX_NETWORK_STAGES-1) then
                        node_ready_y    <= node_ready_y + 1;
                    end if;
                    
                    ready_packets_sent  <= ready_packets_sent + 1;
                    
                else
                    x_in        <= (others => '0');
                    x_in_valid  <= '0';
                
                    node_ready_x    <= 0;
                    node_ready_y    <= 0;    
                    
                end if;
            end if;
        end if;
    end process READY_PACKET_PROC;
    
    READY_DECODER: message_decoder
        generic map (
            COORD_BITS              => COORD_BITS,
            MULTICAST_GROUP_BITS    => MULTICAST_GROUP_BITS,
            MULTICAST_COORD_BITS    => MULTICAST_COORD_BITS,
            
            MATRIX_TYPE_BITS        => MATRIX_TYPE_BITS,
            MATRIX_COORD_BITS       => MATRIX_COORD_BITS,
            MATRIX_ELEMENT_BITS     => MATRIX_ELEMENT_BITS,
            BUS_WIDTH               => BUS_WIDTH
        )
        port map (
            clk                 => clk,
            reset_n             => reset_n,
            
            packet_in           => ready_decoder_packet_in,
            packet_in_valid     => ready_decoder_packet_in_valid,
            
            x_coord_out         => ready_decoder_x_coord_out,
            y_coord_out         => ready_decoder_y_coord_out,
            multicast_group_out => ready_decoder_multicast_group_out,
            done_flag_out       => ready_decoder_done_flag_out,
            result_flag_out     => ready_decoder_result_flag_out,
            matrix_type_out     => ready_decoder_matrix_type_out,
            matrix_x_coord_out  => ready_decoder_matrix_x_coord_out,
            matrix_y_coord_out  => ready_decoder_matrix_y_coord_out,
            matrix_element_out  => ready_decoder_matrix_element_out,
    
            packet_out_valid    => ready_decoder_packet_out_valid,
            packet_read         => ready_decoder_packet_read
        );
        
    ready_decoder_packet_in         <= x_in;
    ready_decoder_packet_in_valid   <= x_in_valid;
    
    READY_DECODER_PRINT: process (clk)
        variable my_line         : line;
        variable my_decoder_line : line;
    begin
        if (rising_edge(clk)) then
            if (reset_n = '1') then
                if (ready_decoder_packet_in_valid = '1') then
                    write(my_line, string'("READY_DECODER: "));
                    write(my_line, string'(" ready_packets_sent = "));
                    write(my_line, ready_packets_sent);
                    
                    write(my_line, string'(", total_packets_received = "));
                    write(my_line, total_packets_received);
                
                    my_decoder_line := print_decoded_message(count, ready_decoder_packet_in, 
                                          ready_decoder_x_coord_out, ready_decoder_y_coord_out,
                                          ready_decoder_multicast_group_out,
                                          ready_decoder_done_flag_out, ready_decoder_result_flag_out,
                                          ready_decoder_matrix_type_out,
                                          ready_decoder_matrix_x_coord_out, ready_decoder_matrix_y_coord_out,
                                          ready_decoder_matrix_element_out);
                                          
                   writeline(output, my_line);
                   writeline(output, my_decoder_line);
                end if;
            end if;
        end if;
    end process READY_DECODER_PRINT;

    ROM: rom_node
        generic map (   
            -- Node parameters
            X_COORD => X_COORD,
            Y_COORD => Y_COORD,
            
            -- Multicast parameters
            USE_MULTICAST           => False,
            MULTICAST_X_COORD       => 1,
            MULTICAST_Y_COORD       => 1,
    
            -- Packet parameters
            COORD_BITS              => COORD_BITS,
            MULTICAST_GROUP_BITS    => MULTICAST_GROUP_BITS,
            MULTICAST_COORD_BITS    => MULTICAST_COORD_BITS,
            MATRIX_TYPE_BITS        => MATRIX_TYPE_BITS,
            MATRIX_COORD_BITS       => MATRIX_COORD_BITS,
            MATRIX_ELEMENT_BITS     => MATRIX_ELEMENT_BITS,
            BUS_WIDTH               => BUS_WIDTH,
    
            FIFO_DEPTH              => NIC_FIFO_DEPTH,
            
            USE_INITIALISATION_FILE => True,
            MATRIX_FILE             => matrix_file,
            ROM_DEPTH               => matrix_file_length,
            ROM_ADDRESS_WIDTH       => ADDRESS_WIDTH,
            
            USE_BURST               => True,
            BURST_LENGTH            => BURST_LENGTH
        )
        port map (
            clk                 => clk,
            reset_n             => reset_n,
            
            rom_read_complete   => rom_read_complete,
    
            x_in                => x_in,
            x_in_valid          => x_in_valid,
            y_in                => y_in,
            y_in_valid          => y_in_valid,
            
            x_out               => x_out,
            x_out_valid         => x_out_valid,
            y_out               => y_out,
            y_out_valid         => y_out_valid
        );

    x_decoder_packet_in       <= x_out;
    x_decoder_packet_in_valid <= x_out_valid;
    
    y_decoder_packet_in       <= y_out;
    y_decoder_packet_in_valid <= y_out_valid;
   
    X_DECODER: message_decoder
        generic map (
            COORD_BITS              => COORD_BITS,
            MULTICAST_GROUP_BITS    => MULTICAST_GROUP_BITS,
            MULTICAST_COORD_BITS    => MULTICAST_COORD_BITS,
            
            MATRIX_TYPE_BITS        => MATRIX_TYPE_BITS,
            MATRIX_COORD_BITS       => MATRIX_COORD_BITS,
            MATRIX_ELEMENT_BITS     => MATRIX_ELEMENT_BITS,
            BUS_WIDTH               => BUS_WIDTH
        )
        port map (
            clk                 => clk,
            reset_n             => reset_n,
            
            packet_in           => x_decoder_packet_in,
            packet_in_valid     => x_decoder_packet_in_valid,
            
            x_coord_out         => x_decoder_x_coord_out,
            y_coord_out         => x_decoder_y_coord_out,
            multicast_group_out => x_decoder_multicast_group_out,
            done_flag_out       => x_decoder_done_flag_out,
            result_flag_out     => x_decoder_result_flag_out,
            matrix_type_out     => x_decoder_matrix_type_out,
            matrix_x_coord_out  => x_decoder_matrix_x_coord_out,
            matrix_y_coord_out  => x_decoder_matrix_y_coord_out,
            matrix_element_out  => x_decoder_matrix_element_out,
    
            packet_out_valid    => x_decoder_packet_out_valid,
            packet_read         => x_decoder_packet_read
        );
        
    X_DECODER_READ: process (clk)
    begin
        if (rising_edge(clk)) then
            if (reset_n = '1') then
                x_decoder_packet_read <= x_decoder_packet_in_valid;
            end if;
        end if;
    end process X_DECODER_READ;
        
    X_DECODER_PRINT: process (clk)
        variable my_line         : line;
        variable my_decoder_line : line;
    begin
        if (rising_edge(clk)) then
            if (reset_n = '0') then
                x_packets_received  <= 0;
            elsif (reset_n = '1') then
                if (x_decoder_packet_in_valid = '1') then
                    x_packets_received  <= x_packets_received + 1;
                
                    write(my_line, string'("X_DECODER: "));
                    write(my_line, string'(" total_packets_received = "));
                    write(my_line, total_packets_received);
                
                    my_decoder_line := print_decoded_message(count, x_decoder_packet_in, 
                                          x_decoder_x_coord_out, x_decoder_y_coord_out,
                                          x_decoder_multicast_group_out,
                                          x_decoder_done_flag_out, x_decoder_result_flag_out,
                                          x_decoder_matrix_type_out,
                                          x_decoder_matrix_x_coord_out, x_decoder_matrix_y_coord_out,
                                          x_decoder_matrix_element_out);
                                          
                   writeline(output, my_line);
                   writeline(output, my_decoder_line);
                end if;
            end if;
        end if;
    end process X_DECODER_PRINT;
        
    Y_DECODER: message_decoder
        generic map (
            COORD_BITS              => COORD_BITS,
            MULTICAST_GROUP_BITS    => MULTICAST_GROUP_BITS,
            MULTICAST_COORD_BITS    => MULTICAST_COORD_BITS,
            
            MATRIX_TYPE_BITS        => MATRIX_TYPE_BITS,
            MATRIX_COORD_BITS       => MATRIX_COORD_BITS,
            MATRIX_ELEMENT_BITS     => MATRIX_ELEMENT_BITS,
            BUS_WIDTH               => BUS_WIDTH
        )
        port map (
            clk                 => clk,
            reset_n             => reset_n,
            
            packet_in           => y_decoder_packet_in,
            packet_in_valid     => y_decoder_packet_in_valid,
            
            x_coord_out         => y_decoder_x_coord_out,
            y_coord_out         => y_decoder_y_coord_out,
            multicast_group_out => y_decoder_multicast_group_out,
            done_flag_out       => y_decoder_done_flag_out,
            result_flag_out     => y_decoder_result_flag_out,
            matrix_type_out     => y_decoder_matrix_type_out,
            matrix_x_coord_out  => y_decoder_matrix_x_coord_out,
            matrix_y_coord_out  => y_decoder_matrix_y_coord_out,
            matrix_element_out  => y_decoder_matrix_element_out,
    
            packet_out_valid    => y_decoder_packet_out_valid,
            packet_read         => y_decoder_packet_read
        );
        
    Y_DECODER_READ: process (clk)
    begin
        if (rising_edge(clk)) then
            if (reset_n = '1') then
                y_decoder_packet_read <= y_decoder_packet_in_valid;
            end if;
        end if;
    end process Y_DECODER_READ;
        
    Y_DECODER_PRINT: process (clk)
        variable my_line         : line;
        variable my_decoder_line : line;
    begin
        if (rising_edge(clk)) then
            if (reset_n = '0') then
                y_packets_received  <= 0;
            elsif (reset_n = '1') then
                if (y_decoder_packet_in_valid = '1') then
                    y_packets_received  <= y_packets_received + 1;
                
                    write(my_line, string'("Y_DECODER: "));
                    write(my_line, string'(" total_packets_received = "));
                    write(my_line, total_packets_received);
                
                    my_decoder_line := print_decoded_message(count, y_decoder_packet_in, 
                                          y_decoder_x_coord_out, y_decoder_y_coord_out,
                                          y_decoder_multicast_group_out,
                                          y_decoder_done_flag_out, y_decoder_result_flag_out,
                                          y_decoder_matrix_type_out,
                                          y_decoder_matrix_x_coord_out, y_decoder_matrix_y_coord_out,
                                          y_decoder_matrix_element_out);
                   
                   writeline(output, my_line);
                   writeline(output, my_decoder_line);
                end if;
            end if;
        end if;
    end process Y_DECODER_PRINT;
    
    total_packets_received  <= x_packets_received + y_packets_received;
    
    READ_COMPLETE: process (clk)
    begin
        if (rising_edge(clk)) then
            if (reset_n = '1') then
                if (total_packets_received = matrix_file_length) then
                    stop;
                end if;
            end if;
        end if;
    end process READ_COMPLETE;

end Behavioral;
