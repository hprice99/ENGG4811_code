library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.math_real.all;

use STD.textio.all;
use IEEE.std_logic_textio.all;

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
    
    -- constant MULTICAST_COORD_BITS   : integer := ceil_log2(NETWORK_ROWS) + 1;
    constant MULTICAST_COORD_BITS   : integer := 0;
    
    constant BUS_WIDTH      : integer := 4 * COORD_BITS + MESSAGE_BITS + MESSAGE_TYPE_BITS + 2 * MULTICAST_COORD_BITS;
    
    constant X_INDEX    : integer := 0;
    constant Y_INDEX    : integer := 1;
    
    -- Custom types
    type t_Coordinate is array (0 to 1) of std_logic_vector((COORD_BITS-1) downto 0);
    type t_Destination is array(0 to (NETWORK_COLS-1), 0 to (NETWORK_ROWS-1)) of t_Coordinate;
    type t_Message is array (0 to (NETWORK_COLS-1), 0 to (NETWORK_ROWS-1)) of std_logic_vector((BUS_WIDTH-1) downto 0);
    type t_MessageValid is array (0 to (NETWORK_COLS-1), 0 to (NETWORK_ROWS-1)) of std_logic;
    type t_Trigger is array (0 to (NETWORK_COLS-1), 0 to (NETWORK_ROWS-1)) of std_logic;
    
    type t_MulticastCoordinate is array (0 to 1) of std_logic_vector((MULTICAST_COORD_BITS-1) downto 0);
    
    -- Message checking FIFOs
    type t_FifoMessage is array (0 to (NETWORK_COLS-1), 0 to (NETWORK_ROWS-1)) of t_Message;
    type t_FifoMessageValid is array (0 to (NETWORK_COLS-1), 0 to (NETWORK_ROWS-1)) of t_MessageValid;
    
    impure function print_packet (port_name : in string; packet : in std_logic_vector)
        return line;

end package hoplite_network_tb_defs;


package body hoplite_network_tb_defs is
 
    impure function print_packet (port_name : in string; packet : in std_logic_vector) return line is
        variable my_line : line;
    begin
        write(my_line, HT & HT);
        write(my_line, port_name);
        write(my_line, string'(": destination = ("));
        write(my_line, to_integer(unsigned(packet((COORD_BITS-1) downto 0))));
        write(my_line, string'(", "));
        write(my_line, to_integer(unsigned(packet((2*COORD_BITS-1) downto COORD_BITS))));
        write(my_line, string'("), source = ("));
        write(my_line, to_integer(unsigned(packet((3*COORD_BITS-1) downto 2*COORD_BITS))));
        write(my_line, string'(", "));
        write(my_line, to_integer(unsigned(packet((4*COORD_BITS-1) downto 3*COORD_BITS))));
        write(my_line, string'("), type = "));
        if (packet(BUS_WIDTH-1) = '1') then
            write(my_line, string'("Broadcast"));
        else
            write(my_line, string'("Unicast"));
        end if;
        write(my_line, string'(", data = "));
        write(my_line, to_integer(unsigned(packet((BUS_WIDTH-MESSAGE_TYPE_BITS-1) downto 4*COORD_BITS))));
        write(my_line, string'(", raw = "));
        write(my_line, packet((BUS_WIDTH-1) downto 0));
        
        return my_line;
    end function print_packet;
 
end package body hoplite_network_tb_defs;