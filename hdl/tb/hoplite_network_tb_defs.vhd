library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

-- Random stimulus
use ieee.math_real.all;

library xil_defaultlib;
use xil_defaultlib.math_functions.all;

package hoplite_network_tb_defs is 

    constant MAX_COUNT          : integer := 2000;
    
    constant MESSAGE_BURST      : integer := 32;
    
    -- Number of times message output is triggered
    constant MAX_MESSAGE_COUNT  : integer := 2 * MESSAGE_BURST;
    
    constant PE_READY_FREQUENCY : integer := 5;
    
    -- Size of message data in packets
    constant MESSAGE_BITS       : integer := 32;
    constant MESSAGE_TYPE_BITS  : integer := 1;
    
    -- Constants
    constant NETWORK_ROWS   : integer := 2;
    constant NETWORK_COLS   : integer := 2;
    constant NETWORK_NODES  : integer := NETWORK_ROWS * NETWORK_COLS;
    constant COORD_BITS     : integer := ceil_log2(max(NETWORK_ROWS, NETWORK_COLS));
    constant BUS_WIDTH      : integer := 4 * COORD_BITS + MESSAGE_BITS + MESSAGE_TYPE_BITS;
    
    constant X_INDEX    : integer := 0;
    constant Y_INDEX    : integer := 1;
    
    -- Custom types
    type t_Coordinate is array (0 to 1) of std_logic_vector((COORD_BITS-1) downto 0);
    type t_Destination is array(0 to (NETWORK_COLS-1), 0 to (NETWORK_ROWS-1)) of t_Coordinate;
    type t_Message is array (0 to (NETWORK_COLS-1), 0 to (NETWORK_ROWS-1)) of std_logic_vector((BUS_WIDTH-1) downto 0);
    type t_MessageValid is array (0 to (NETWORK_COLS-1), 0 to (NETWORK_ROWS-1)) of std_logic;
    type t_Trigger is array (0 to (NETWORK_COLS-1), 0 to (NETWORK_ROWS-1)) of std_logic;
    
    -- Message checking FIFOs
    type t_FifoMessage is array (0 to (NETWORK_COLS-1), 0 to (NETWORK_ROWS-1)) of t_Message;
    type t_FifoMessageValid is array (0 to (NETWORK_COLS-1), 0 to (NETWORK_ROWS-1)) of t_MessageValid;

end package hoplite_network_tb_defs;


package body hoplite_network_tb_defs is
 
end package body hoplite_network_tb_defs;