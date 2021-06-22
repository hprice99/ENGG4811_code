library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

use ieee.math_real.all;

-- Package Declaration Section
package math_functions is 
        
    function ceil_log2 (Arg : in positive)
    	return integer;
       
end package math_functions;
 
-- Package Body Section
package body math_functions is
 
    -----------------------------------------------------------------------------------
    -- Combine the ceil and log2 functions.  ceil_log2(x) then gives the minimum number
    -- of bits required to represent 'x'.  ceil_log2(4) = 2, ceil_log2(5) = 3, etc.
    -----------------------------------------------------------------------------------
    function ceil_log2 (Arg : positive) return integer is
        variable i  : integer := 0;
    begin
        while (Arg > (2 ** i)) loop
            i := i + 1;
        end loop;
        
        return i;
    end function ceil_log2;
 
end package body math_functions;
