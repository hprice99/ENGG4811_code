----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 08/09/2021 08:11:36 PM
-- Design Name: 
-- Module Name: message_encoder_tb - Behavioral
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
use ieee.std_logic_unsigned.all;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

use STD.textio.all;
use IEEE.std_logic_textio.all;

library xil_defaultlib;
use xil_defaultlib.math_functions.all;
use xil_defaultlib.conv_functions.all;
use xil_defaultlib.fox_defs.all;

entity message_encoder_tb is
--  Port ( );
end message_encoder_tb;

architecture Behavioral of message_encoder_tb is

    component message_encoder
        generic (
            COORD_BITS              : integer := 2;
            MULTICAST_GROUP_BITS    : integer := 1;
            MATRIX_TYPE_BITS        : integer := 1;
            MATRIX_COORD_BITS       : integer := 8;
            MATRIX_ELEMENT_BITS     : integer := 32;
            BUS_WIDTH               : integer := 56
        );
        port (
            clk                         : in std_logic;
            reset_n                     : in std_logic;
            
            x_coord_in                  : in std_logic_vector((COORD_BITS-1) downto 0);
            x_coord_in_valid            : in std_logic;
            
            y_coord_in                  : in std_logic_vector((COORD_BITS-1) downto 0);
            y_coord_in_valid            : in std_logic;

            multicast_group_in          : in std_logic_vector((MULTICAST_GROUP_BITS-1) downto 0);
            multicast_group_in_valid    : in std_logic;

            done_flag_in                : in std_logic;
            done_flag_in_valid          : in std_logic;

            result_flag_in              : in std_logic;
            result_flag_in_valid        : in std_logic;

            matrix_type_in              : in std_logic_vector((MATRIX_TYPE_BITS-1) downto 0);
            matrix_type_in_valid        : in std_logic;

            matrix_x_coord_in           : in std_logic_vector((MATRIX_COORD_BITS-1) downto 0);
            matrix_x_coord_in_valid     : in std_logic;

            matrix_y_coord_in           : in std_logic_vector((MATRIX_COORD_BITS-1) downto 0);
            matrix_y_coord_in_valid     : in std_logic;
            
            matrix_element_in           : in std_logic_vector((MATRIX_ELEMENT_BITS-1) downto 0);
            matrix_element_in_valid     : in std_logic;
            
            packet_complete_in          : in std_logic;
            
            packet_out                  : out std_logic_vector((BUS_WIDTH-1) downto 0);
            packet_out_valid            : out std_logic
        );
    end component message_encoder;
    
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

    signal clk          : std_logic;
    constant clk_period : time := 10 ns;
    
    signal reset_n  : std_logic;
    
    -- Encoder inputs
    type t_NodeMatrix is array (0 to (FOX_MATRIX_ELEMENTS-1)) of std_logic_vector((MATRIX_ELEMENT_BITS-1) downto 0);
    
    constant A_0    : t_NodeMatrix := ((
            0   => int_to_slv(1, MATRIX_ELEMENT_BITS),
            1   => int_to_slv(1, MATRIX_ELEMENT_BITS),
            2   => int_to_slv(1, MATRIX_ELEMENT_BITS),
            3   => int_to_slv(1, MATRIX_ELEMENT_BITS)
        ));
    constant B_0    : t_NodeMatrix := ((
            0   => int_to_slv(1, MATRIX_ELEMENT_BITS),
            1   => int_to_slv(1, MATRIX_ELEMENT_BITS),
            2   => int_to_slv(1, MATRIX_ELEMENT_BITS),
            3   => int_to_slv(1, MATRIX_ELEMENT_BITS)
        ));
        
    constant A_1    : t_NodeMatrix := ((
            0   => int_to_slv(2, MATRIX_ELEMENT_BITS),
            1   => int_to_slv(2, MATRIX_ELEMENT_BITS),
            2   => int_to_slv(2, MATRIX_ELEMENT_BITS),
            3   => int_to_slv(2, MATRIX_ELEMENT_BITS)
        ));
    constant B_1    : t_NodeMatrix := ((
            0   => int_to_slv(2, MATRIX_ELEMENT_BITS),
            1   => int_to_slv(2, MATRIX_ELEMENT_BITS),
            2   => int_to_slv(2, MATRIX_ELEMENT_BITS),
            3   => int_to_slv(2, MATRIX_ELEMENT_BITS)
        ));
        
    constant A_2    : t_NodeMatrix := ((
            0   => int_to_slv(3, MATRIX_ELEMENT_BITS),
            1   => int_to_slv(3, MATRIX_ELEMENT_BITS),
            2   => int_to_slv(3, MATRIX_ELEMENT_BITS),
            3   => int_to_slv(3, MATRIX_ELEMENT_BITS)
        ));  
    constant B_2    : t_NodeMatrix := ((
            0   => int_to_slv(3, MATRIX_ELEMENT_BITS),
            1   => int_to_slv(3, MATRIX_ELEMENT_BITS),
            2   => int_to_slv(3, MATRIX_ELEMENT_BITS),
            3   => int_to_slv(3, MATRIX_ELEMENT_BITS)
        ));
        
    constant A_3    : t_NodeMatrix := ((
            0   => int_to_slv(4, MATRIX_ELEMENT_BITS),
            1   => int_to_slv(4, MATRIX_ELEMENT_BITS),
            2   => int_to_slv(4, MATRIX_ELEMENT_BITS),
            3   => int_to_slv(4, MATRIX_ELEMENT_BITS)
        ));  
    constant B_3    : t_NodeMatrix := ((
            0   => int_to_slv(4, MATRIX_ELEMENT_BITS),
            1   => int_to_slv(4, MATRIX_ELEMENT_BITS),
            2   => int_to_slv(4, MATRIX_ELEMENT_BITS),
            3   => int_to_slv(4, MATRIX_ELEMENT_BITS)
        )); 
        
    type t_NodeMatrices is array (0 to (NETWORK_COLS-1), 0 to (NETWORK_ROWS-1)) of t_NodeMatrix;
    
    signal A_matrices    : t_NodeMatrices := ((A_0, A_1), (A_2, A_3));
    signal B_matrices    : t_NodeMatrices := ((B_0, B_1), (B_2, B_3));
        
    type t_DestCoord is array (0 to (NETWORK_COLS-1), 0 to (NETWORK_ROWS-1)) of std_logic_vector((COORD_BITS-1) downto 0);
    type t_MulticastGroup is array (0 to (NETWORK_COLS-1), 0 to (NETWORK_ROWS-1)) of std_logic_vector((MULTICAST_GROUP_BITS-1) downto 0);        
    type t_MatrixType is array (0 to (NETWORK_COLS-1), 0 to (NETWORK_ROWS-1)) of std_logic_vector((MATRIX_TYPE_BITS-1) downto 0);
    type t_MatrixCoord is array (0 to (NETWORK_COLS-1), 0 to (NETWORK_ROWS-1)) of std_logic_vector((MATRIX_COORD_BITS-1) downto 0);
    type t_MatrixElement is array (0 to (NETWORK_COLS-1), 0 to (NETWORK_ROWS-1)) of std_logic_vector((MATRIX_ELEMENT_BITS-1) downto 0);
    type t_Counter is array (0 to (NETWORK_COLS-1), 0 to (NETWORK_ROWS-1)) of integer;
    
    type e_MatrixType is (A, B);
    type t_CurrentMatrixType is array (0 to (NETWORK_COLS-1), 0 to (NETWORK_ROWS-1)) of e_MatrixType;

    signal x_dest           : t_DestCoord;
    signal x_dest_valid     : t_MessageValid;
    
    signal y_dest           : t_DestCoord;
    signal y_dest_valid     : t_MessageValid;
    
    signal multicast_group          : t_MulticastGroup;
    signal multicast_group_valid    : t_MessageValid;
    
    signal done_flag        : t_MessageValid;
    signal done_flag_valid  : t_MessageValid;
    
    signal result_flag          : t_MessageValid;
    signal result_flag_valid    : t_MessageValid;
    
    signal matrix_type          : t_MatrixType;
    signal matrix_type_valid    : t_MessageValid;
    
    signal matrix_x_coord       : t_MatrixCoord;
    signal matrix_x_coord_valid : t_MessageValid;
    
    signal matrix_y_coord       : t_MatrixCoord;
    signal matrix_y_coord_valid : t_MessageValid;
    
    signal matrix_element       : t_MatrixElement;
    signal matrix_element_valid : t_MessageValid;
    
    signal encoder_packet_complete      : t_MessageValid;
    
    signal encoder_packet_out       : t_Message;
    signal encoder_packet_out_valid : t_MessageValid;

    -- Internal testbench signals
    signal packet_sent   : t_MessageValid;

    signal current_matrix_type    : t_CurrentMatrixType;

    signal a_packets_received : t_Counter;
    signal b_packets_received : t_Counter;
    
    signal a_packets_done : t_MessageValid;
    signal b_packets_done : t_MessageValid;
    
    type t_MatrixCoordLookup is array (0 to (FOX_MATRIX_ELEMENTS-1)) of integer;
    
    signal matrix_x_coord_lookup    : t_MatrixCoordLookup;
    signal matrix_y_coord_lookup    : t_MatrixCoordLookup;
    
    -- Decoder signals
    signal decoder_packet_in        : t_Message;
    signal decoder_packet_in_valid  : t_MessageValid;
    
    signal decoder_x_coord_out          : t_DestCoord;
    signal decoder_y_coord_out          : t_DestCoord;
    signal decoder_multicast_group_out  : t_MulticastGroup;
    signal decoder_done_flag_out        : t_MessageValid;
    signal decoder_result_flag_out      : t_MessageValid;
    signal decoder_matrix_type_out      : t_MatrixType;
    signal decoder_matrix_x_coord_out   : t_MatrixCoord;
    signal decoder_matrix_y_coord_out   : t_MatrixCoord;
    signal decoder_matrix_element_out   : t_MatrixElement;
    
    signal decoder_packet_out_valid     : t_MessageValid;
    signal decoder_packet_read          : t_MessageValid;

    type t_State is (START, SET_A, SET_B, SEND, DECODE, INCREMENT, CHOOSE_MATRIX, DONE);
    type t_States is array (0 to (NETWORK_COLS-1), 0 to (NETWORK_ROWS-1)) of t_State;
    signal current_state    : t_States;
    signal next_state       : t_States;

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
    
    MATRIX_X_COORD_LOOKUP_GEN: for x in 0 to (FOX_MATRIX_SIZE-1) generate
        MATRIX_Y_COORD_LOOKUP_GEN: for y in 0 to (FOX_MATRIX_SIZE-1) generate
            constant index  : integer := y * FOX_MATRIX_SIZE + x;
        begin
            matrix_x_coord_lookup(index) <= x;
            matrix_y_coord_lookup(index) <= y;
        end generate MATRIX_Y_COORD_LOOKUP_GEN;
    end generate MATRIX_X_COORD_LOOKUP_GEN;
        
    -- Generate the network of encoders
    NETWORK_ROW_GEN: for i in 0 to (NETWORK_ROWS-1) generate
        NETWORK_COL_GEN: for j in 0 to (NETWORK_COLS-1) generate
            constant prev_y         : integer := ((i-1) mod NETWORK_ROWS);
            constant prev_x         : integer := ((j-1) mod NETWORK_COLS);
            constant curr_y         : integer := i;
            constant curr_x         : integer := j;
            constant next_y         : integer := ((i+1) mod NETWORK_ROWS);
            constant next_x         : integer := ((j+1) mod NETWORK_COLS);
            constant node_number    : integer := i * NETWORK_ROWS + j;
            constant y_offset       : integer := i * (FOX_MATRIX_SIZE);
            constant x_offset       : integer := j * (FOX_MATRIX_SIZE);
        begin
            STATE_MEMORY: process (clk)
            begin
                if (rising_edge(clk)) then
                    if (reset_n = '0') then
                        current_state(curr_x, curr_y)   <= START;
                    else
                        current_state(curr_x, curr_y)   <= next_state(curr_x, curr_y);
                    end if;
                end if;
            end process STATE_MEMORY;

            STATE_TRANSITION: process (current_state(curr_x, curr_y), 
                    encoder_packet_out_valid(curr_x, curr_y), 
                    decoder_packet_out_valid(curr_x, curr_y),
                    a_packets_received(curr_x, curr_y),
                    b_packets_received(curr_x, curr_y))
            begin
                case current_state(curr_x, curr_y) is
                    when START => 
                        next_state(curr_x, curr_y)  <= SET_A;
                    when SET_A =>
                        next_state(curr_x, curr_y)  <= SEND;
                    when SET_B =>
                        next_state(curr_x, curr_y)  <= SEND;
                    when SEND =>
                        if (encoder_packet_out_valid(curr_x, curr_y) = '1') then
                            next_state(curr_x, curr_y)  <= DECODE;
                        else
                            next_state(curr_x, curr_y)  <= SEND;
                        end if;
                    when DECODE =>
                        next_state(curr_x, curr_y) <= INCREMENT;
                    when INCREMENT =>
                        next_state(curr_x, curr_y) <= CHOOSE_MATRIX;
                    when CHOOSE_MATRIX =>
                        if (a_packets_received(curr_x, curr_y) < FOX_MATRIX_ELEMENTS) then
                            next_state(curr_x, curr_y) <= SET_A;
                        elsif (b_packets_received(curr_x, curr_y) < FOX_MATRIX_ELEMENTS) then
                            next_state(curr_x, curr_y) <= SET_B;
                        else
                            next_state(curr_x, curr_y) <= DONE;
                        end if;
                    when others =>
                        next_state(curr_x, curr_y) <= current_state(curr_x, curr_y);
                end case;
            end process STATE_TRANSITION;

            STATE_OUTPUT: process (current_state(curr_x, curr_y), 
                    encoder_packet_out_valid(curr_x, curr_y), 
                    decoder_packet_out_valid(curr_x, curr_y),
                    a_packets_received(curr_x, curr_y),
                    b_packets_received(curr_x, curr_y))
            begin
                -- Reset valid signals
                x_dest_valid(curr_x, curr_y)            <= '0';
                y_dest_valid(curr_x, curr_y)            <= '0';
                multicast_group_valid(curr_x, curr_y)   <= '0';
                done_flag_valid(curr_x, curr_y)         <= '0';
                result_flag_valid(curr_x, curr_y)       <= '0';
                matrix_type_valid(curr_x, curr_y)       <= '0';
                matrix_x_coord_valid(curr_x, curr_y)    <= '0';
                matrix_y_coord_valid(curr_x, curr_y)    <= '0';
                matrix_element_valid(curr_x, curr_y)    <= '0';

                encoder_packet_complete(curr_x, curr_y) <= '0';
                decoder_packet_read(curr_x, curr_y)     <= '0';
            
                case current_state(curr_x, curr_y) is
                    when START =>
                        x_dest_valid(curr_x, curr_y)            <= '0';
                        y_dest_valid(curr_x, curr_y)            <= '0';
                        multicast_group_valid(curr_x, curr_y)   <= '0';
                        done_flag_valid(curr_x, curr_y)         <= '0';
                        result_flag_valid(curr_x, curr_y)       <= '0';
                        matrix_type_valid(curr_x, curr_y)       <= '0';
                        matrix_x_coord_valid(curr_x, curr_y)    <= '0';
                        matrix_y_coord_valid(curr_x, curr_y)    <= '0';
                        matrix_element_valid(curr_x, curr_y)    <= '0';
                        
                        encoder_packet_complete(curr_x, curr_y) <= '0';
                        
                        decoder_packet_read(curr_x, curr_y)     <= '0';
                    when SET_A =>
                        x_dest(curr_x, curr_y)                  <= int_to_slv(curr_x, COORD_BITS);
                        x_dest_valid(curr_x, curr_y)            <= '1';

                        y_dest(curr_x, curr_y)                  <= int_to_slv(curr_y, COORD_BITS);
                        y_dest_valid(curr_x, curr_y)            <= '1';

                        multicast_group(curr_x, curr_y)         <= "1";
                        multicast_group_valid(curr_x, curr_y)   <= '1';

                        done_flag(curr_x, curr_y)               <= '0';
                        done_flag_valid(curr_x, curr_y)         <= '1';

                        result_flag(curr_x, curr_y)             <= '0';
                        result_flag_valid(curr_x, curr_y)       <= '1';

                        matrix_type(curr_x, curr_y)             <= "0";
                        matrix_type_valid(curr_x, curr_y)       <= '1';

                        matrix_x_coord(curr_x, curr_y)          <= int_to_slv(matrix_x_coord_lookup(a_packets_received(curr_x, curr_y)), MATRIX_COORD_BITS);
                        matrix_x_coord_valid(curr_x, curr_y)    <= '1';

                        matrix_y_coord(curr_x, curr_y)          <= int_to_slv(matrix_y_coord_lookup(a_packets_received(curr_x, curr_y)), MATRIX_COORD_BITS);
                        matrix_y_coord_valid(curr_x, curr_y)    <= '1';

                        matrix_element(curr_x, curr_y)          <= A_matrices(curr_y, curr_x)(a_packets_received(curr_x, curr_y));
                        matrix_element_valid(curr_x, curr_y)    <= '1';
                    
                    when SET_B =>
                        x_dest(curr_x, curr_y)                  <= int_to_slv(curr_x, COORD_BITS);
                        x_dest_valid(curr_x, curr_y)            <= '1';

                        y_dest(curr_x, curr_y)                  <= int_to_slv(curr_y, COORD_BITS);
                        y_dest_valid(curr_x, curr_y)            <= '1';

                        multicast_group(curr_x, curr_y)         <= "0";
                        multicast_group_valid(curr_x, curr_y)   <= '1';

                        done_flag(curr_x, curr_y)               <= '0';
                        done_flag_valid(curr_x, curr_y)         <= '1';

                        result_flag(curr_x, curr_y)             <= '0';
                        result_flag_valid(curr_x, curr_y)       <= '1';

                        matrix_type(curr_x, curr_y)             <= "1";
                        matrix_type_valid(curr_x, curr_y)       <= '1';

                        matrix_x_coord(curr_x, curr_y)          <= int_to_slv(matrix_x_coord_lookup(b_packets_received(curr_x, curr_y)), MATRIX_COORD_BITS);
                        matrix_x_coord_valid(curr_x, curr_y)    <= '1';

                        matrix_y_coord(curr_x, curr_y)          <= int_to_slv(matrix_y_coord_lookup(b_packets_received(curr_x, curr_y)), MATRIX_COORD_BITS);
                        matrix_y_coord_valid(curr_x, curr_y)    <= '1';

                        matrix_element(curr_x, curr_y)          <= B_matrices(curr_y, curr_x)(b_packets_received(curr_x, curr_y));
                        matrix_element_valid(curr_x, curr_y)    <= '1';

                    when SEND =>
                        encoder_packet_complete(curr_x, curr_y) <= '1';

                    when DECODE =>
                        -- Packet read out of decoder
                        decoder_packet_read(curr_x, curr_y) <= '1';

                    when INCREMENT =>
                        encoder_packet_complete(curr_x, curr_y) <= '0';
                    when others =>
                        -- Reset valid signals
                        x_dest_valid(curr_x, curr_y)            <= '0';
                        y_dest_valid(curr_x, curr_y)            <= '0';
                        multicast_group_valid(curr_x, curr_y)   <= '0';
                        done_flag_valid(curr_x, curr_y)         <= '0';
                        result_flag_valid(curr_x, curr_y)       <= '0';
                        matrix_type_valid(curr_x, curr_y)       <= '0';
                        matrix_x_coord_valid(curr_x, curr_y)    <= '0';
                        matrix_y_coord_valid(curr_x, curr_y)    <= '0';
                        matrix_element_valid(curr_x, curr_y)    <= '0';
                        
                        encoder_packet_complete(curr_x, curr_y) <= '0';
                        
                        decoder_packet_read(curr_x, curr_y)     <= '0';
                end case;
            end process STATE_OUTPUT;
            
            ELEMENT_COUNTER: process (clk)
            begin
                if (rising_edge(clk) and reset_n = '1') then
                    if (current_state(curr_x, curr_y) = START) then
                        a_packets_received(curr_x, curr_y)    <= 0;
                        b_packets_received(curr_x, curr_y)    <= 0;
                    elsif (current_state(curr_x, curr_y) = INCREMENT) then
                        if (a_packets_received(curr_x, curr_y) < FOX_MATRIX_ELEMENTS) then
                            a_packets_received(curr_x, curr_y) <= a_packets_received(curr_x, curr_y) + 1;
                        elsif (b_packets_received(curr_x, curr_y) < FOX_MATRIX_ELEMENTS) then
                            b_packets_received(curr_x, curr_y) <= b_packets_received(curr_x, curr_y) + 1;
                        end if;
                    end if;
                end if;
            end process ELEMENT_COUNTER;

            ENCODER: message_encoder
                generic map (
                    COORD_BITS              => COORD_BITS,
                    MULTICAST_GROUP_BITS    => MULTICAST_GROUP_BITS,
                    MATRIX_TYPE_BITS        => MATRIX_TYPE_BITS,
                    MATRIX_COORD_BITS       => MATRIX_COORD_BITS,
                    MATRIX_ELEMENT_BITS     => MATRIX_ELEMENT_BITS,
                    BUS_WIDTH               => BUS_WIDTH
                )
                port map (
                    clk                         => clk,
                    reset_n                     => reset_n,
                    
                    x_coord_in                  => x_dest(curr_x, curr_y),
                    x_coord_in_valid            => x_dest_valid(curr_x, curr_y),
                    
                    y_coord_in                  => y_dest(curr_x, curr_y),
                    y_coord_in_valid            => y_dest_valid(curr_x, curr_y),
                    
                    multicast_group_in          => multicast_group(curr_x, curr_y),
                    multicast_group_in_valid    => multicast_group_valid(curr_x, curr_y),
        
                    done_flag_in                => done_flag(curr_x, curr_y),
                    done_flag_in_valid          => done_flag_valid(curr_x, curr_y),
        
                    result_flag_in              => result_flag(curr_x, curr_y),
                    result_flag_in_valid        => result_flag_valid(curr_x, curr_y),
        
                    matrix_type_in              => matrix_type(curr_x, curr_y),
                    matrix_type_in_valid        => matrix_type_valid(curr_x, curr_y),
        
                    matrix_x_coord_in           => matrix_x_coord(curr_x, curr_y),
                    matrix_x_coord_in_valid     => matrix_x_coord_valid(curr_x, curr_y),
        
                    matrix_y_coord_in           => matrix_y_coord(curr_x, curr_y),
                    matrix_y_coord_in_valid     => matrix_y_coord_valid(curr_x, curr_y),
        
                    matrix_element_in           => matrix_element(curr_x, curr_y),
                    matrix_element_in_valid     => matrix_element_valid(curr_x, curr_y),
                    
                    packet_complete_in          => encoder_packet_complete(curr_x, curr_y),
                    
                    packet_out                  => encoder_packet_out(curr_x, curr_y),
                    packet_out_valid            => encoder_packet_out_valid(curr_x, curr_y)
                );
                
            decoder_packet_in(curr_x, curr_y)       <= encoder_packet_out(curr_x, curr_y);
            decoder_packet_in_valid(curr_x, curr_y) <= encoder_packet_out_valid(curr_x, curr_y);

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
                    
                    packet_in           => decoder_packet_in(curr_x, curr_y),
                    packet_in_valid     => decoder_packet_in_valid(curr_x, curr_y),
                    
                    x_coord_out         => decoder_x_coord_out(curr_x, curr_y),
                    y_coord_out         => decoder_y_coord_out(curr_x, curr_y),
                    multicast_group_out => decoder_multicast_group_out(curr_x, curr_y),
                    done_flag_out       => decoder_done_flag_out(curr_x, curr_y),
                    result_flag_out     => decoder_result_flag_out(curr_x, curr_y),
                    matrix_type_out     => decoder_matrix_type_out(curr_x, curr_y),
                    matrix_x_coord_out  => decoder_matrix_x_coord_out(curr_x, curr_y),
                    matrix_y_coord_out  => decoder_matrix_y_coord_out(curr_x, curr_y),
                    matrix_element_out  => decoder_matrix_element_out(curr_x, curr_y),
        
                    packet_out_valid    => decoder_packet_out_valid(curr_x, curr_y),
                    packet_read         => decoder_packet_read(curr_x, curr_y)
                );

            -- Process to print encoded packets
            PRINT_OUTPUT: process (clk)
                variable my_encoder_output_line             : line;
                variable my_encoder_binary_file_line        : line;
                constant my_encoder_binary_file_name        : string := "encoded_node" & integer'image(node_number) & "_binary.txt";
                file WriteEncodeBinaryFile                  : text open WRITE_MODE is my_encoder_binary_file_name;
                
                variable my_encoder_hex_file_line           : line;
                constant my_encoder_hex_file_name           : string := "encoded_node" & integer'image(node_number) & "_hex.txt";
                file WriteEncodeHexFile                     : text open WRITE_MODE is my_encoder_hex_file_name;

                variable my_decoder_output_line     : line;
                variable my_decoder_file_line       : line;
                constant my_decoder_file_name       : string := "decoded_node" & integer'image(node_number) & ".txt";
                file WriteDecodeFile                : text open WRITE_MODE is my_decoder_file_name;
            begin
                if (rising_edge(clk) and reset_n = '1') then
                    if (encoder_packet_out_valid(curr_x, curr_y) = '1') then
                        write(my_encoder_output_line, string'("Node number = "));
                        write(my_encoder_output_line, node_number);
                        write(my_encoder_output_line, string'(", encoded packet: "));
                        write(my_encoder_output_line, encoder_packet_out(curr_x, curr_y));
                        write(my_encoder_output_line, string'(", "));
                        hwrite(my_encoder_output_line, encoder_packet_out(curr_x, curr_y));
                        writeline(output, my_encoder_output_line);
                        
                        write(my_encoder_binary_file_line, encoder_packet_out(curr_x, curr_y));
                        writeline(WriteEncodeBinaryFile, my_encoder_binary_file_line);
                        
                        hwrite(my_encoder_hex_file_line, encoder_packet_out(curr_x, curr_y));
                        writeline(WriteEncodeHexFile, my_encoder_hex_file_line);
                    end if;
                    
                    if (decoder_packet_read(curr_x, curr_y) = '1') then
                        write(my_decoder_output_line, string'("Node number = "));
                        write(my_decoder_output_line, node_number);
                        write(my_decoder_output_line, string'(", encoded packet: "));
                        hwrite(my_decoder_output_line, decoder_packet_in(curr_x, curr_y));
                        
                        write(my_decoder_output_line, string'(", decoded packet: "));
                        
                        write(my_decoder_output_line, string'("dest = ("));
                        write(my_decoder_output_line, slv_to_int(decoder_x_coord_out(curr_x, curr_y)));
                        write(my_decoder_output_line, string'(", "));
                        write(my_decoder_output_line, slv_to_int(decoder_y_coord_out(curr_x, curr_y)));
                        write(my_decoder_output_line, string'(")"));
                        
                        write(my_decoder_output_line, string'(", multicast group = "));
                        write(my_decoder_output_line, slv_to_int(decoder_multicast_group_out(curr_x, curr_y)));
                        
                        write(my_decoder_output_line, string'(", done flag = "));
                        write(my_decoder_output_line, decoder_done_flag_out(curr_x, curr_y));
                        
                        write(my_decoder_output_line, string'(", result flag = "));
                        write(my_decoder_output_line, decoder_result_flag_out(curr_x, curr_y));
                        
                        write(my_decoder_output_line, string'(", matrix type = "));
                        
                        if (slv_to_int(decoder_matrix_type_out(curr_x, curr_y)) = 0) then
                            write(my_decoder_output_line, string'("A"));
                        elsif (slv_to_int(decoder_matrix_type_out(curr_x, curr_y)) = 1) then
                            write(my_decoder_output_line, string'("B"));
                        end if;
                        
                        write(my_decoder_output_line, string'(", matrix coordinate = ("));
                        write(my_decoder_output_line, slv_to_int(decoder_matrix_x_coord_out(curr_x, curr_y)));
                        write(my_decoder_output_line, string'(", "));
                        write(my_decoder_output_line, slv_to_int(decoder_matrix_y_coord_out(curr_x, curr_y)));
                        write(my_decoder_output_line, string'(")"));
                        
                        write(my_decoder_output_line, string'(", matrix element = "));
                        write(my_decoder_output_line, slv_to_int(decoder_matrix_element_out(curr_x, curr_y)));
                        
                        writeline(output, my_decoder_output_line);

                        write(my_decoder_file_line, string'("Node number = "));
                        write(my_decoder_file_line, node_number);
                        write(my_decoder_file_line, string'(", encoded packet: "));
                        hwrite(my_decoder_file_line, decoder_packet_in(curr_x, curr_y));
                        
                        write(my_decoder_file_line, string'(", decoded packet: "));
                        
                        write(my_decoder_file_line, string'("dest = ("));
                        write(my_decoder_file_line, slv_to_int(decoder_x_coord_out(curr_x, curr_y)));
                        write(my_decoder_file_line, string'(", "));
                        write(my_decoder_file_line, slv_to_int(decoder_y_coord_out(curr_x, curr_y)));
                        write(my_decoder_file_line, string'(")"));
                        
                        write(my_decoder_file_line, string'(", multicast group = "));
                        write(my_decoder_file_line, slv_to_int(decoder_multicast_group_out(curr_x, curr_y)));
                        
                        write(my_decoder_file_line, string'(", done flag = "));
                        write(my_decoder_file_line, decoder_done_flag_out(curr_x, curr_y));
                        
                        write(my_decoder_file_line, string'(", result flag = "));
                        write(my_decoder_file_line, decoder_result_flag_out(curr_x, curr_y));
                        
                        write(my_decoder_file_line, string'(", matrix type = "));
                        
                        if (slv_to_int(decoder_matrix_type_out(curr_x, curr_y)) = 0) then
                            write(my_decoder_file_line, string'("A"));
                        elsif (slv_to_int(decoder_matrix_type_out(curr_x, curr_y)) = 1) then
                            write(my_decoder_file_line, string'("B"));
                        end if;

                        write(my_decoder_file_line, string'(", matrix coordinate = ("));
                        write(my_decoder_file_line, slv_to_int(decoder_matrix_x_coord_out(curr_x, curr_y)));
                        write(my_decoder_file_line, string'(", "));
                        write(my_decoder_file_line, slv_to_int(decoder_matrix_y_coord_out(curr_x, curr_y)));
                        write(my_decoder_file_line, string'(")"));
                        
                        write(my_decoder_file_line, string'(", matrix element = "));
                        write(my_decoder_file_line, slv_to_int(decoder_matrix_element_out(curr_x, curr_y)));
                        
                        writeline(WriteDecodeFile, my_decoder_file_line);
                    end if;
                end if;
            end process PRINT_OUTPUT;
        end generate NETWORK_COL_GEN;
    end generate NETWORK_ROW_GEN;    

end Behavioral;
