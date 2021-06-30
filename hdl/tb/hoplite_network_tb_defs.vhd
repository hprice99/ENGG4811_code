library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

-- Random stimulus
use ieee.math_real.all;


package hoplite_network_tb_defs is 

    constant MAX_COUNT          : integer := 10;
    
    -- Number of times message output is triggered
    constant MAX_MESSAGE_COUNT  : integer := 1;
    
    constant PE_READY_FREQUENCY : integer := 5;
    
    -- Size of message data in packets
    constant MESSAGE_BITS       : integer := 32;

end package hoplite_network_tb_defs;


package body hoplite_network_tb_defs is
 
end package body hoplite_network_tb_defs;