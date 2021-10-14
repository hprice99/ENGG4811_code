library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

use IEEE.NUMERIC_STD.ALL;

entity message_encoder is
    Generic (
        COORD_BITS              : integer := 2;
        
        MULTICAST_GROUP_BITS    : integer := 1;
        MULTICAST_COORD_BITS    : integer := 1;
        MULTICAST_X_COORD       : integer := 1;
        MULTICAST_Y_COORD       : integer := 1;
        
        MATRIX_TYPE_BITS        : integer := 1;
        MATRIX_COORD_BITS       : integer := 8;
        MATRIX_ELEMENT_BITS     : integer := 32;
        BUS_WIDTH               : integer := 56
    );
    Port (
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
end message_encoder;

architecture Behavioral of message_encoder is

    signal dest_x_coord, dest_y_coord : std_logic_vector((COORD_BITS-1) downto 0);
    signal multicast_group  : std_logic_vector((MULTICAST_GROUP_BITS-1) downto 0);
    signal dest_multicast_x_coord, dest_multicast_y_coord : std_logic_vector((MULTICAST_COORD_BITS-1) downto 0); 
    signal done_flag, result_flag   : std_logic;
    signal matrix_type      : std_logic_vector((MATRIX_TYPE_BITS-1) downto 0);
    signal matrix_x_coord, matrix_y_coord   : std_logic_vector((MATRIX_COORD_BITS-1) downto 0);
    signal matrix_element   : std_logic_vector((MATRIX_ELEMENT_BITS-1) downto 0);

begin

    -- Message format 0 -- x_dest | y_dest | dest_multicast_x_coord | dest_multicast_y_coord | done | result | matrix | matrix_x_coord | matrix_y_coord | matrix_element -- (BUS_WIDTH-1)
    packet_out          <= matrix_element & matrix_y_coord & matrix_x_coord & 
                            matrix_type & result_flag & done_flag & 
                            dest_multicast_y_coord & dest_multicast_x_coord & dest_y_coord & dest_x_coord;
    packet_out_valid    <= packet_complete_in; 
    
    FIELD_FF: process (clk)
    begin
        if (rising_edge(clk)) then
            if (reset_n = '0') then
                dest_x_coord            <= (others => '0');
                dest_y_coord            <= (others => '0');
                multicast_group         <= (others => '0');
                dest_multicast_x_coord  <= (others => '0');
                dest_multicast_y_coord  <= (others => '0');
                done_flag               <= '0';
                result_flag             <= '0';
                matrix_type             <= (others => '0');
                matrix_x_coord          <= (others => '0');
                matrix_y_coord          <= (others => '0');
                matrix_element          <= (others => '0');
            else
                if (x_coord_in_valid = '1') then
                    dest_x_coord <= x_coord_in;
                end if;
                
                if (y_coord_in_valid = '1') then
                    dest_y_coord <= y_coord_in;
                end if;
                
                if (multicast_group_in_valid = '1') then
                    multicast_group <= multicast_group_in;
                    
                    if (to_integer(unsigned(multicast_group_in)) /= 0) then
                        dest_multicast_x_coord   <= std_logic_vector(to_unsigned(MULTICAST_X_COORD, MULTICAST_COORD_BITS));
                        dest_multicast_y_coord   <= std_logic_vector(to_unsigned(MULTICAST_Y_COORD, MULTICAST_COORD_BITS));
                    else
                        dest_multicast_x_coord   <= (others => '0');
                        dest_multicast_y_coord   <= (others => '0');
                    end if;
                end if;

                if (done_flag_in_valid = '1') then
                    done_flag <= done_flag_in;
                end if;

                if (result_flag_in_valid = '1') then
                    result_flag <= result_flag_in;
                end if;

                if (matrix_type_in_valid = '1') then
                    matrix_type <= matrix_type_in;
                end if;

                if (matrix_x_coord_in_valid = '1') then
                    matrix_x_coord <= matrix_x_coord_in;
                end if;

                if (matrix_y_coord_in_valid = '1') then
                    matrix_y_coord <= matrix_y_coord_in;
                end if;
            
                if (matrix_element_in_valid = '1') then
                    matrix_element <= matrix_element_in;
                end if;
            end if;
        end if;
    end process FIELD_FF;

end Behavioral;
