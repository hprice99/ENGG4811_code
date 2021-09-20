library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

package packet_defs is 

    constant MULTICAST_GROUP_BITS   : integer := 1;

    -- Size of message data in packets
    constant COORD_BITS             : integer := 2;
    constant MULTICAST_COORD_BITS   : integer := 1;
    constant DONE_FLAG_BITS         : integer := 1;
    constant RESULT_FLAG_BITS       : integer := 1;
    constant MATRIX_TYPE_BITS       : integer := 1;
    constant MATRIX_COORD_BITS      : integer := 8;
    constant MATRIX_ELEMENT_BITS    : integer := 32;
    constant BUS_WIDTH              : integer := 
            2*COORD_BITS + 2*MULTICAST_COORD_BITS + DONE_FLAG_BITS + 
            RESULT_FLAG_BITS + MATRIX_TYPE_BITS + 2*MATRIX_COORD_BITS + 
            MATRIX_ELEMENT_BITS;

    constant X_INDEX    : integer := 0;
    constant Y_INDEX    : integer := 1;

    type t_MulticastCoordinate is array (0 to 1) of std_logic_vector((MULTICAST_COORD_BITS-1) downto 0);
    type t_Coordinate is array (0 to 1) of std_logic_vector((COORD_BITS-1) downto 0);

end package packet_defs;


package body packet_defs is
 
end package body packet_defs;