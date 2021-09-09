library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

library xil_defaultlib;
use xil_defaultlib.hoplite_network_tb_defs.all;

package multicast_defs is 

    -- Constants
    -- Each row is a multicast group
    constant MULTICAST_GROUP_NODES      : integer := NETWORK_COLS;
    
    constant MULTICAST_NETWORK_ROWS     : integer := NETWORK_ROWS;
    constant MULTICAST_NETWORK_COLS     : integer := 1;

    -- Custom types
    type t_NodeToMulticastPackets is array (0 to (MULTICAST_GROUP_NODES-1)) of std_logic_vector((BUS_WIDTH-1) downto 0);
    type t_NodeToMulticastPacketsValid is array (0 to (MULTICAST_GROUP_NODES-1)) of std_logic;
    
    type t_CombinedNodeToMulticastPackets is array (1 to (MULTICAST_NETWORK_COLS), 1 to (MULTICAST_NETWORK_ROWS)) of t_NodeToMulticastPackets;
    type t_CombinedNodeToMulticastPacketValid is array (1 to (MULTICAST_NETWORK_COLS), 1 to (MULTICAST_NETWORK_ROWS)) of t_NodeToMulticastPacketsValid;

    type t_MulticastToMulticastPackets is array (1 to (MULTICAST_NETWORK_COLS), 1 to (MULTICAST_NETWORK_ROWS)) of std_logic_vector((BUS_WIDTH-1) downto 0);
    type t_MulticastToMulticastPacketsValid is array (1 to (MULTICAST_NETWORK_COLS), 1 to (MULTICAST_NETWORK_ROWS)) of std_logic;
    
    type t_MulticastToNodePackets is array (1 to (MULTICAST_NETWORK_COLS), 1 to (MULTICAST_NETWORK_ROWS)) of std_logic_vector((BUS_WIDTH-1) downto 0);
    type t_MulticastToNodePacketsValid is array (1 to (MULTICAST_NETWORK_COLS), 1 to (MULTICAST_NETWORK_ROWS)) of std_logic;

end package multicast_defs;

package body multicast_defs is
 
end package body multicast_defs;