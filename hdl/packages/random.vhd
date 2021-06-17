library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

-- Random stimulus
use ieee.math_real.all;

-- Package Declaration Section
package random is 

  function rand_slv (len, seed : in integer)
        return std_logic_vector;
       
end package random;
 
-- Package Body Section
package body random is
 
    function rand_slv (len, seed : integer) return std_logic_vector is
      variable r : real;
      variable slv : std_logic_vector(len - 1 downto 0);
      variable seed1 : integer;
      variable seed2 : integer := 999;
    begin
        seed1 := seed;      

        for i in slv'range loop
            uniform(seed1, seed2, r);
            
            if (r > 0.5) then
                slv(i) := '1';
            else
                slv(i) := '0';
            end if;
        end loop;
        return slv;
    end function;
 
end package body random;