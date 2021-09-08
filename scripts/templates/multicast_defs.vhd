library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

library xil_defaultlib;
use xil_defaultlib.packet_defs.all;

package multicast_defs is 

    -- Constants
    constant MULTICAST_GROUP_NODES  : integer := {{ multicastConfig.multicastClusterNodes }};

    -- Custom types
    type t_MulticastGroupPackets is array (0 to (MULTICAST_GROUP_NODES-1)) of std_logic_vector((BUS_WIDTH-1) downto 0);
    type t_MulticastGroupPacketsValid is array (0 to (MULTICAST_GROUP_NODES-1)) of std_logic;
    
    type t_CombinedMulticastGroupPackets is array (1 to (MULTICAST_NETWORK_COLS), 1 to (MULTICAST_NETWORK_ROWS)) of t_MulticastGroupPackets;
    type t_CombinedMulticastGroupPacketsValid is array (1 to (MULTICAST_NETWORK_COLS), 1 to (MULTICAST_NETWORK_ROWS)) of t_MulticastGroupPacketsValid;

    type t_MulticastToMulticastPackets is array (1 to (MULTICAST_NETWORK_COLS), 1 to (MULTICAST_NETWORK_ROWS)) of std_logic_vector((BUS_WIDTH-1) downto 0);
    type t_MulticastNetworkPacketsValid is array (1 to (MULTICAST_NETWORK_COLS), 1 to (MULTICAST_NETWORK_ROWS)) of std_logic;

end package multicast_defs;

package body multicast_defs is
 
end package body multicast_defs;