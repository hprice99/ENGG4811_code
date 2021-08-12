----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 08/11/2021 06:40:24 PM
-- Design Name: 
-- Module Name: fifo_sync_memory_initialise_tb - Behavioral
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

library xil_defaultlib;
use xil_defaultlib.math_functions.all;
use xil_defaultlib.conv_functions.all;
use xil_defaultlib.fox_defs.all;

use STD.textio.all;
use IEEE.std_logic_textio.all;

use std.env.finish;
use std.env.stop;

entity fifo_sync_memory_initialise_tb is
--  Port ( );
end fifo_sync_memory_initialise_tb;

architecture Behavioral of fifo_sync_memory_initialise_tb is

    signal clk          : std_logic;
    constant clk_period : time := 10 ns;
    
    signal reset_n  : std_logic;

    component fifo_sync_memory_initialise
        generic (
            BUS_WIDTH   : integer := 32;
            FIFO_DEPTH  : integer := 64;
            
            INITIALISATION_FILE     : string := "none";
            INITIALISATION_LENGTH   : integer := 0
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
    end component fifo_sync_memory_initialise;
    
    constant matrix_file        : string := "matrix.txt";
    constant matrix_file_length : integer := FOX_FIFO_DEPTH;
    
    signal write_en     : std_logic;
    signal write_data   : std_logic_vector((BUS_WIDTH-1) downto 0);
    
    signal read_en      : std_logic;
    signal read_data    : std_logic_vector((BUS_WIDTH-1) downto 0);
    
    signal full         : std_logic;
    signal empty        : std_logic;
    
    component message_decoder
        generic (
            COORD_BITS              : integer := 2;
            MULTICAST_GROUP_BITS    : integer := 1;
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
    
    -- Decoder signals
    signal decoder_packet_in        : std_logic_vector((BUS_WIDTH-1) downto 0);
    signal decoder_packet_in_valid  : std_logic;
    
    signal decoder_x_coord_out          : std_logic_vector((COORD_BITS-1) downto 0);
    signal decoder_y_coord_out          : std_logic_vector((COORD_BITS-1) downto 0);
    signal decoder_multicast_group_out  : std_logic_vector((MULTICAST_GROUP_BITS-1) downto 0);
    signal decoder_done_flag_out        : std_logic;
    signal decoder_result_flag_out      : std_logic;
    signal decoder_matrix_type_out      : std_logic_vector((MATRIX_TYPE_BITS-1) downto 0);
    signal decoder_matrix_x_coord_out   : std_logic_vector((MATRIX_COORD_BITS-1) downto 0);
    signal decoder_matrix_y_coord_out   : std_logic_vector((MATRIX_COORD_BITS-1) downto 0);
    signal decoder_matrix_element_out   : std_logic_vector((MATRIX_ELEMENT_BITS-1) downto 0);
    
    signal decoder_packet_out_valid     : std_logic;
    signal decoder_packet_read          : std_logic;

    type t_State is (START, DECODE, READ, DONE);
    signal current_state    : t_State;
    signal next_state       : t_State;
    
    signal entries_read     : integer;
    
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

    write_en    <= '0';
    write_data  <= (others => '0');

    FIFO: fifo_sync_memory_initialise
        generic map (
            BUS_WIDTH   => BUS_WIDTH,
            FIFO_DEPTH  => FOX_FIFO_DEPTH,
            
            INITIALISATION_FILE     => matrix_file,
            INITIALISATION_LENGTH   => matrix_file_length
        )
        port map (
            clk         => clk,
            reset_n     => reset_n,
            
            write_en    => write_en,
            write_data  => write_data,
            
            read_en     => read_en,
            read_data   => read_data,
            
            full        => full,
            empty       => empty
        );
        
    decoder_packet_in       <= read_data;
    decoder_packet_in_valid <= read_en;
        
    DECODER: message_decoder
        generic map (
            COORD_BITS              => COORD_BITS,
            MULTICAST_GROUP_BITS    => MULTICAST_GROUP_BITS,
            MATRIX_TYPE_BITS        => MATRIX_TYPE_BITS,
            MATRIX_COORD_BITS       => MATRIX_COORD_BITS,
            MATRIX_ELEMENT_BITS     => MATRIX_ELEMENT_BITS,
            BUS_WIDTH               => BUS_WIDTH
        )
        port map (
            clk                 => clk,
            reset_n             => reset_n,
            
            packet_in           => decoder_packet_in,
            packet_in_valid     => decoder_packet_in_valid,
            
            x_coord_out         => decoder_x_coord_out,
            y_coord_out         => decoder_y_coord_out,
            multicast_group_out => decoder_multicast_group_out,
            done_flag_out       => decoder_done_flag_out,
            result_flag_out     => decoder_result_flag_out,
            matrix_type_out     => decoder_matrix_type_out,
            matrix_x_coord_out  => decoder_matrix_x_coord_out,
            matrix_y_coord_out  => decoder_matrix_y_coord_out,
            matrix_element_out  => decoder_matrix_element_out,
    
            packet_out_valid    => decoder_packet_out_valid,
            packet_read         => decoder_packet_read
        );
        
    STATE_MEMORY: process (clk)
    begin
        if (rising_edge(clk)) then
            if (reset_n = '0') then
                current_state   <= START;
            else
                current_state   <= next_state;
            end if;
        end if;
    end process STATE_MEMORY;

    STATE_TRANSITION: process (current_state)
    begin
        case current_state is
            when START => 
                next_state  <= DECODE;
            when DECODE =>
                next_state  <= READ;
            when READ =>
                if (entries_read < matrix_file_length) then
                    next_state  <= DECODE;
                else
                    next_state  <= DONE;
                end if;
            when others =>
                next_state <= current_state;
        end case;
    end process STATE_TRANSITION;

    STATE_OUTPUT: process (current_state)
    begin
        decoder_packet_read     <= '0';
        read_en                 <= '0';
    
        case current_state is
            when START  =>
                entries_read    <= 0;
            when DECODE =>
                decoder_packet_read <= '1';
                entries_read        <= entries_read + 1;
            when READ   => 
                read_en         <= '1';
            when others =>
                decoder_packet_read     <= '0';
                read_en                 <= '0';
        end case;
    end process STATE_OUTPUT;
    
    -- Process to print decoded packets
    PRINT_DECODER_OUTPUT: process (clk)
        variable my_decoder_output_line     : line;
    begin
        if (rising_edge(clk) and reset_n = '1') then
            if (decoder_packet_read = '1') then
                write(my_decoder_output_line, string'("Encoded packet: "));
                hwrite(my_decoder_output_line, decoder_packet_in);
                
                write(my_decoder_output_line, string'(", decoded packet: "));
                
                write(my_decoder_output_line, string'("dest = ("));
                write(my_decoder_output_line, slv_to_int(decoder_x_coord_out));
                write(my_decoder_output_line, string'(", "));
                write(my_decoder_output_line, slv_to_int(decoder_y_coord_out));
                write(my_decoder_output_line, string'(")"));
                
                write(my_decoder_output_line, string'(", multicast group = "));
                write(my_decoder_output_line, slv_to_int(decoder_multicast_group_out));
                
                write(my_decoder_output_line, string'(", done flag = "));
                write(my_decoder_output_line, decoder_done_flag_out);
                
                write(my_decoder_output_line, string'(", result flag = "));
                write(my_decoder_output_line, decoder_result_flag_out);
                
                write(my_decoder_output_line, string'(", matrix type = "));
                
                if (slv_to_int(decoder_matrix_type_out) = 0) then
                    write(my_decoder_output_line, string'("A"));
                elsif (slv_to_int(decoder_matrix_type_out) = 1) then
                    write(my_decoder_output_line, string'("B"));
                end if;
                
                write(my_decoder_output_line, string'(", matrix coordinate = ("));
                write(my_decoder_output_line, slv_to_int(decoder_matrix_x_coord_out));
                write(my_decoder_output_line, string'(", "));
                write(my_decoder_output_line, slv_to_int(decoder_matrix_y_coord_out));
                write(my_decoder_output_line, string'(")"));
                
                write(my_decoder_output_line, string'(", matrix element = "));
                write(my_decoder_output_line, slv_to_int(decoder_matrix_element_out));
                
                writeline(output, my_decoder_output_line);
            end if;
        end if;
    end process PRINT_DECODER_OUTPUT;
    
    PRINT_OUTPUT: process (clk)
        variable my_output_line     : line;
    begin
        if (rising_edge(clk) and reset_n = '1') then
            if (current_state = DONE) then
                write(my_output_line, string'("DONE"));
                writeline(output, my_output_line);
                
                stop;
            end if;
        end if;
    end process PRINT_OUTPUT;

end Behavioral;
