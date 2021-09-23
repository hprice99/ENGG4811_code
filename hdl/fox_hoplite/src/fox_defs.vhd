library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

library xil_defaultlib;
use xil_defaultlib.packet_defs.all;
use xil_defaultlib.matrix_config.all;
use xil_defaultlib.math_functions.all;

package fox_defs is 

    -- Constants
    constant NETWORK_ROWS   : integer := 3;
    constant NETWORK_COLS   : integer := 2;
    constant NETWORK_NODES  : integer := NETWORK_ROWS * NETWORK_COLS;

    -- Fox's algorithm network paramters
    constant FOX_NETWORK_STAGES  : integer := 2;
    constant FOX_NETWORK_NODES   : integer := FOX_NETWORK_STAGES ** 2;

    -- Result node parameters
    constant RESULT_X_COORD  : integer := 0;
    constant RESULT_Y_COORD  : integer := 0;

    -- ROM node parameters
    constant ROM_X_COORD  : integer := 0;
    constant ROM_Y_COORD  : integer := 2;

    -- NIC parameters
    constant FOX_PE_TO_NETWORK_FIFO_DEPTH   : integer := 512;
    constant FOX_NETWORK_TO_PE_FIFO_DEPTH   : integer := 512;

    constant RESULT_PE_TO_NETWORK_FIFO_DEPTH    : integer := 2048;
    constant RESULT_NETWORK_TO_PE_FIFO_DEPTH    : integer := 2048;

    constant RESULT_UART_FIFO_DEPTH : integer := 512;

    -- Custom types
    type t_Destination is array(0 to (NETWORK_COLS-1), 0 to (NETWORK_ROWS-1)) of t_Coordinate;
    type t_Message is array (0 to (NETWORK_COLS-1), 0 to (NETWORK_ROWS-1)) of std_logic_vector((BUS_WIDTH-1) downto 0);
    type t_MessageValid is array (0 to (NETWORK_COLS-1), 0 to (NETWORK_ROWS-1)) of std_logic;
    type t_Char is array (0 to (FOX_NETWORK_STAGES-1), 0 to (FOX_NETWORK_STAGES-1)) of std_logic_vector(7 downto 0);
    type t_MatrixOut is array (0 to (FOX_NETWORK_STAGES-1), 0 to (FOX_NETWORK_STAGES-1)) of std_logic_vector((MATRIX_ELEMENT_BITS-1) downto 0);

end package fox_defs;

package body fox_defs is
 
end package body fox_defs;