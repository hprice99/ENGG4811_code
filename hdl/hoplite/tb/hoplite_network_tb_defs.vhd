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
    constant MESSAGE_BITS       : integer := 8;
    constant MESSAGE_TYPE_BITS  : integer := 1;
    
    -- Constants
    constant NETWORK_ROWS   : integer := 2;
    constant NETWORK_COLS   : integer := 2;
    constant NETWORK_NODES  : integer := NETWORK_ROWS * NETWORK_COLS;
    constant COORD_BITS     : integer := ceil_log2(max(NETWORK_ROWS, NETWORK_COLS));
    
    constant MULTICAST_COORD_BITS   : integer := ceil_log2(NETWORK_ROWS) + 1;
    -- constant MULTICAST_COORD_BITS   : integer := 0;
    
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

    constant DESTINATION_X_START    : integer := 0;
    constant DESTINATION_X_END      : integer := DESTINATION_X_START + COORD_BITS - 1;
    
    constant DESTINATION_Y_START    : integer := DESTINATION_X_END + 1;
    constant DESTINATION_Y_END      : integer := DESTINATION_Y_START + COORD_BITS - 1;
    
    constant MULTICAST_X_START      : integer := DESTINATION_Y_END + 1;
    constant MULTICAST_X_END        : integer := MULTICAST_X_START + MULTICAST_COORD_BITS - 1;
    
    constant MULTICAST_Y_START      : integer := MULTICAST_X_END + 1;
    constant MULTICAST_Y_END        : integer := MULTICAST_Y_START + MULTICAST_COORD_BITS - 1;
    
    constant SOURCE_X_START         : integer := MULTICAST_Y_END + 1;
    constant SOURCE_X_END           : integer := SOURCE_X_START + COORD_BITS - 1;
    
    constant SOURCE_Y_START         : integer := SOURCE_X_END + 1;
    constant SOURCE_Y_END           : integer := SOURCE_Y_START + COORD_BITS - 1;
    
    constant MESSAGE_START          : integer := SOURCE_Y_END + 1;
    constant MESSAGE_END            : integer := MESSAGE_START + MESSAGE_BITS - 1;
    
    constant MESSAGE_TYPE_START     : integer := MESSAGE_END + 1;
    constant MESSAGE_TYPE_END       : integer := MESSAGE_TYPE_START + MESSAGE_TYPE_BITS - 1;
    
    function get_dest_coord (packet : in std_logic_vector) 
        return t_Coordinate;
        
    function get_multicast_coord (packet : in std_logic_vector)
        return t_MulticastCoordinate;
        
    function get_source_coord (packet : in std_logic_vector)
        return t_Coordinate;
        
    function get_message (packet : in std_logic_vector)
        return std_logic_vector;
        
    function get_message_type (packet : in std_logic_vector)
        return std_logic_vector;

end package hoplite_network_tb_defs;


package body hoplite_network_tb_defs is

    function get_dest_coord (packet : in std_logic_vector) return t_Coordinate is
        variable destination : t_Coordinate;
    begin
        destination(X_INDEX)    := packet(DESTINATION_X_END downto DESTINATION_X_START);
        destination(Y_INDEX)    := packet(DESTINATION_Y_END downto DESTINATION_Y_START);
        
        return destination;
    end function get_dest_coord;
    
    function get_multicast_coord (packet : in std_logic_vector) return t_MulticastCoordinate is
        variable multicastCoord : t_MulticastCoordinate;
    begin
        multicastCoord(X_INDEX) := packet(MULTICAST_X_END downto MULTICAST_X_START);
        multicastCoord(Y_INDEX) := packet(MULTICAST_Y_END downto MULTICAST_Y_START);
        
        return multicastCoord;
    end function get_multicast_coord;
    
    function get_source_coord (packet : in std_logic_vector) return t_Coordinate is
        variable source : t_Coordinate;
    begin
        source(X_INDEX) := packet(SOURCE_X_END downto SOURCE_X_START);
        source(Y_INDEX) := packet(SOURCE_Y_END downto SOURCE_Y_START);
        
        return source;
    end function get_source_coord;
    
    function get_message (packet : in std_logic_vector) return std_logic_vector is
        variable message    : std_logic_vector((MESSAGE_BITS-1) downto 0);
    begin
        message := packet(MESSAGE_END downto MESSAGE_START);
        
        return message;
    end function get_message;
    
    function get_message_type (packet : in std_logic_vector) return std_logic_vector is
        variable message_type   : std_logic_vector((MESSAGE_TYPE_BITS-1) downto 0);
    begin
        message_type    := packet(MESSAGE_TYPE_END downto MESSAGE_TYPE_START);
        
        return message_type;
    end function get_message_type;
 
    impure function print_packet (port_name : in string; packet : in std_logic_vector) return line is
        variable destination            : t_Coordinate;
        variable multicast_destination  : t_MulticastCoordinate;
        variable source                 : t_Coordinate;
        variable message                : std_logic_vector((MESSAGE_BITS-1) downto 0);
        variable message_type           : std_logic_vector((MESSAGE_TYPE_BITS-1) downto 0);
        variable my_line : line;
    begin
        destination             := get_dest_coord(packet);
        multicast_destination   := get_multicast_coord(packet);
        source                  := get_source_coord(packet);
        message                 := get_message(packet);
        message_type            := get_message_type(packet); 
    
        write(my_line, HT & HT);
        write(my_line, port_name);
        write(my_line, string'(": destination = ("));
        write(my_line, to_integer(unsigned(destination(X_INDEX))));
        write(my_line, string'(", "));
        write(my_line, to_integer(unsigned(destination(Y_INDEX))));
        
        if (MULTICAST_COORD_BITS > 0) then
            write(my_line, string'("), multicast destination = ("));
            write(my_line, to_integer(unsigned(multicast_destination(X_INDEX))));
            write(my_line, string'(", "));
            write(my_line, to_integer(unsigned(multicast_destination(Y_INDEX))));
        end if;
        
        write(my_line, string'("), source = ("));
        write(my_line, to_integer(unsigned(source(X_INDEX))));
        write(my_line, string'(", "));
        write(my_line, to_integer(unsigned(source(Y_INDEX))));
        write(my_line, string'("), type = "));
        if (message_type /= "0") then
            write(my_line, string'("Broadcast"));
        else
            write(my_line, string'("Unicast"));
        end if;
        write(my_line, string'(", data = "));
        write(my_line, to_integer(unsigned(message)));
        write(my_line, string'(", raw = "));
        write(my_line, packet((BUS_WIDTH-1) downto 0));
        
        return my_line;
    end function print_packet;
 
end package body hoplite_network_tb_defs;