library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

library xil_defaultlib;
use xil_defaultlib.packet_defs.all;

package multicast_defs is 

    -- Constants
    constant MULTICAST_CLUSTER_NODES    : integer := 2;

    -- Custom types
    type t_MulticastClusterPackets is array (0 to (MULTICAST_CLUSTER_NODES-1)) of std_logic_vector((BUS_WIDTH-1) downto 0);
    type t_MulticastClusterPacketsValid is array (0 to (MULTICAST_CLUSTER_NODES-1)) of std_logic;

end package multicast_defs;

package body multicast_defs is
 
end package body multicast_defs;