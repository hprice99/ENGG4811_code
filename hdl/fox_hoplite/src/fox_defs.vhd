library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

library xil_defaultlib;
use xil_defaultlib.matrix_config.all;
use xil_defaultlib.math_functions.all;

package fox_defs is 

    -- Constants
    constant NETWORK_ROWS   : integer := 2;
    constant NETWORK_COLS   : integer := 2;
    constant NETWORK_NODES  : integer := NETWORK_ROWS * NETWORK_COLS;

    -- Fox's algorithm network paramters
    constant FOX_NETWORK_STAGES  : integer := 2;
    constant FOX_NETWORK_NODES   : integer := FOX_NETWORK_STAGES ** 2;

    -- Result node parameters
    constant RESULT_X_COORD  : integer := 0;
    constant RESULT_Y_COORD  : integer := 0;
    
    constant MULTICAST_GROUP_BITS   : integer := 1;

    -- Size of message data in packets
    constant COORD_BITS             : integer := 1;
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
            
    -- NIC parameters
    constant FOX_FIFO_DEPTH     : integer := 2 * FOX_MATRIX_ELEMENTS;
    constant RESULT_FIFO_DEPTH  : integer := TOTAL_MATRIX_ELEMENTS;

    constant X_INDEX    : integer := 0;
    constant Y_INDEX    : integer := 1;

    -- Custom types
    type t_Coordinate is array (0 to 1) of std_logic_vector((COORD_BITS-1) downto 0);
    type t_Destination is array(0 to (NETWORK_COLS-1), 0 to (NETWORK_ROWS-1)) of t_Coordinate;
    type t_MulticastCoordinate is array (0 to 1) of std_logic_vector((MULTICAST_COORD_BITS-1) downto 0);
    type t_Message is array (0 to (NETWORK_COLS-1), 0 to (NETWORK_ROWS-1)) of std_logic_vector((BUS_WIDTH-1) downto 0);
    type t_MessageValid is array (0 to (NETWORK_COLS-1), 0 to (NETWORK_ROWS-1)) of std_logic;
    type t_Char is array (0 to (FOX_NETWORK_STAGES-1), 0 to (FOX_NETWORK_STAGES-1)) of std_logic_vector(7 downto 0);
    type t_Matrix is array (0 to (FOX_NETWORK_STAGES-1), 0 to (FOX_NETWORK_STAGES-1)) of std_logic_vector(31 downto 0);

end package fox_defs;


package body fox_defs is
 
end package body fox_defs;