library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

library xil_defaultlib;
use xil_defaultlib.packet_defs.all;

entity message_decoder is
    Generic (
        COORD_BITS              : integer := 2;
        MULTICAST_GROUP_BITS    : integer := 1;
        MULTICAST_COORD_BITS    : integer := 1;
        MATRIX_TYPE_BITS        : integer := 1;
        MATRIX_COORD_BITS       : integer := 8;
        MATRIX_ELEMENT_BITS     : integer := 32;
        BUS_WIDTH               : integer := 56
    );
    Port (
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
end message_decoder;

architecture Behavioral of message_decoder is

    signal latest_packet    : std_logic_vector((BUS_WIDTH-1) downto 0);
    
    signal multicast_x_coord, multicast_y_coord : std_logic_vector((MULTICAST_COORD_BITS-1) downto 0);
    signal multicast_coord_combined : std_logic_vector((2*MULTICAST_COORD_BITS-1) downto 0);

    signal dest_coord   : t_Coordinate;
    signal multicast_coord  : t_MulticastCoordinate;
    signal matrix_coord : t_MatrixCoordinate;

begin
    latest_packet       <= packet_in;

    -- Message format 0 -- x_dest | y_dest | multicast_x_coord | multicast_y_coord | done | result | matrix | matrix_x_coord | matrix_y_coord | matrix_element -- (BUS_WIDTH-1)
    dest_coord          <= get_dest_coord(latest_packet);
    x_coord_out         <= dest_coord(X_INDEX);
    y_coord_out         <= dest_coord(Y_INDEX);
    
    multicast_coord             <= get_multicast_coord(latest_packet);
    multicast_x_coord           <= multicast_coord(X_INDEX);
    multicast_y_coord           <= multicast_coord(Y_INDEX);
    multicast_coord_combined    <= multicast_y_coord & multicast_x_coord;
    
    with multicast_coord_combined select
        multicast_group_out <= "0" when "00",
                               "1" when others;
    
    done_flag_out       <= get_done_flag(latest_packet);
    result_flag_out     <= get_result_flag(latest_packet);
    matrix_type_out     <= get_matrix_type(latest_packet);
    
    matrix_coord        <= get_matrix_coord(latest_packet);
    matrix_x_coord_out  <= matrix_coord(X_INDEX);
    matrix_y_coord_out  <= matrix_coord(Y_INDEX);
    matrix_element_out  <= get_matrix_element(latest_packet);
    
    -- Hold packet_out_valid high from when packet_in_valid is high to when the message is read, then reset
    VALID_FF: process (clk)
    begin
        if (rising_edge(clk)) then
            if (reset_n = '0') then
                packet_out_valid <= '0';
            else
                if (packet_read <= '1') then
                    packet_out_valid <= '0';
                elsif (packet_in_valid = '1') then
                    packet_out_valid <= '1';
                end if;
            end if;
        end if;
    end process VALID_FF;

end Behavioral;
