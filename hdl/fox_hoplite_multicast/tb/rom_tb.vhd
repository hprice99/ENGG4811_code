library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;

library xil_defaultlib;
use xil_defaultlib.packet_defs.all;
use xil_defaultlib.matrix_config.all;
use xil_defaultlib.fox_defs.all;
use xil_defaultlib.math_functions.all;
use xil_defaultlib.conv_functions.all;

use STD.textio.all;
use IEEE.std_logic_textio.all;

use std.env.finish;
use std.env.stop;

entity rom_tb is
end rom_tb;

architecture Behavioral of rom_tb is

    signal clk          : std_logic;
    constant clk_period : time := 10 ns;
    
    signal reset_n  : std_logic;

    component rom is
        generic (
            BUS_WIDTH       : integer := 32;
            ROM_DEPTH       : integer := 64;
            ADDRESS_WIDTH   : integer := 6;
            
            INITIALISATION_FILE : string    := "none"
        );
        port (
            clk         : in std_logic;
    
            read_en     : in std_logic;
            read_addr   : in std_logic_vector((ADDRESS_WIDTH-1) downto 0);
            read_data   : out std_logic_vector((BUS_WIDTH-1) downto 0)
        );
    end component rom;
    
    constant matrix_file        : string := "combined.mif";
    constant matrix_file_length : integer := 2 * TOTAL_MATRIX_ELEMENTS;
    
    constant ADDRESS_WIDTH  : integer := ceil_log2(matrix_file_length);
    
    signal read_en      : std_logic;
    signal read_address : std_logic_vector((ADDRESS_WIDTH-1) downto 0);
    signal read_data    : std_logic_vector((BUS_WIDTH-1) downto 0);
    
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

    type t_State is (START, READ, DECODE, DONE);
    signal current_state    : t_State;
    signal next_state       : t_State;
    
    signal entries_read     : integer;
    
    type t_Matrix is array (0 to (TOTAL_MATRIX_SIZE-1), 0 to (TOTAL_MATRIX_SIZE-1)) of integer;
    signal A : t_Matrix;
    signal B : t_Matrix;
    
    type t_Offset is array (0 to (FOX_NETWORK_STAGES-1), 0 to (FOX_NETWORK_STAGES-1)) of integer;
    constant matrix_x_offsets : t_Offset  := (0 => (0, FOX_MATRIX_SIZE), 1 => (0, FOX_MATRIX_SIZE));
    constant matrix_y_offsets : t_Offset  := (0 => (0, 0), 1 => (FOX_MATRIX_SIZE, FOX_MATRIX_SIZE));
    
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

    decoder_packet_in       <= read_data;
    decoder_packet_in_valid <= read_en;
    
    ROM_MEMORY: rom 
        generic map (
            BUS_WIDTH       => BUS_WIDTH,
            ROM_DEPTH       => matrix_file_length,
            ADDRESS_WIDTH   => ADDRESS_WIDTH,
            
            INITIALISATION_FILE => matrix_file
        )
        port map (
            clk         => clk,
            
            read_en     => read_en,
            read_addr   => read_address,
            read_data   => read_data
        );
        
    DECODER: message_decoder
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
                next_state  <= READ;
            when READ =>
                next_state  <= DECODE;
            when DECODE =>
                if (entries_read < matrix_file_length) then
                    next_state  <= READ;
                else
                    next_state  <= DONE;
                end if;
            when others =>
                next_state <= current_state;
        end case;
    end process STATE_TRANSITION;

    STATE_OUTPUT: process (current_state)
        variable dest_x_coord   : integer;
        variable dest_y_coord   : integer;
        variable matrix_x_coord : integer;
        variable matrix_y_coord : integer;
        variable matrix_type    : integer;
        variable matrix_element : integer;
    begin
        decoder_packet_read     <= '0';
        read_en                 <= '0';
    
        case current_state is
            when START  =>
                entries_read    <= 0;
            when DECODE =>
                decoder_packet_read <= '1';
                entries_read        <= entries_read + 1;
                
                dest_x_coord    := slv_to_int(decoder_x_coord_out);
                dest_y_coord    := slv_to_int(decoder_y_coord_out);
                matrix_x_coord  := slv_to_int(decoder_matrix_x_coord_out) + FOX_MATRIX_SIZE * dest_x_coord;
                matrix_y_coord  := slv_to_int(decoder_matrix_y_coord_out) + FOX_MATRIX_SIZE * dest_y_coord;
                matrix_type     := slv_to_int(decoder_matrix_type_out);
                matrix_element  := slv_to_int(decoder_matrix_element_out);
                
                -- Assign packet to matrix
                if (matrix_type = 0) then
                    A(matrix_x_coord, matrix_y_coord)   <= matrix_element;
                elsif (matrix_type = 1) then
                    B(matrix_x_coord, matrix_y_coord)   <= matrix_element;
                end if;
            when READ   => 
                read_en             <= '1';
                read_address        <= std_logic_vector(to_unsigned(entries_read, ADDRESS_WIDTH));
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
                
                write(my_output_line, string'("A = [" & LF));
                for y in 0 to (TOTAL_MATRIX_SIZE-1) loop
                
                    write(my_output_line, string'(HT & HT));
                    
                    for x in 0 to (TOTAL_MATRIX_SIZE-1) loop
                        write(my_output_line, A(x, y));
                        write(my_output_line, string'(",  "));
                    end loop;
                    
                    writeline(output, my_output_line);
                end loop;
                write(my_output_line, string'("]"));
                writeline(output, my_output_line);
                
                write(my_output_line, LF);
                
                write(my_output_line, string'("B = [" & LF));
                for y in 0 to (TOTAL_MATRIX_SIZE-1) loop
                
                    write(my_output_line, string'(HT & HT));
                    
                    for x in 0 to (TOTAL_MATRIX_SIZE-1) loop
                        write(my_output_line, B(x, y));
                        write(my_output_line, string'(",  "));
                    end loop;
                    
                    writeline(output, my_output_line);
                end loop;
                write(my_output_line, string'("]"));
                writeline(output, my_output_line);
                
                stop;
            end if;
        end if;
    end process PRINT_OUTPUT;

end Behavioral;
