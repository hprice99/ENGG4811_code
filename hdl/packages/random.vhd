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
        
    function rand_logic (threshold : in real; seed : in integer)
        return std_logic;
       
end package random;
 
-- Package Body Section
package body random is
 
    function rand_slv (len, seed : integer) return std_logic_vector is
      variable r : real;
      variable slv : std_logic_vector((len-1) downto 0);
      variable seed1 : integer;
      variable seed2 : integer;
    begin
        seed1 := seed;      
        seed2 := 2*seed;

        for i in 0 to seed2 loop
            uniform(seed1, seed2, r);
        end loop;   

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
    
    
    function rand_logic (threshold : real; seed : integer) return std_logic is
      variable r : real;
      variable b : std_logic;
      variable seed1 : integer;
      variable seed2 : integer;
    begin
        seed1 := seed;      
        seed2 := 2*seed;

        for i in 0 to seed2 loop
            uniform(seed1, seed2, r);
        end loop;
        
        if (r > threshold) then
            b := '0';
        else
            b := '1';
        end if;
        
        -- report "The value of 'r' is " & real'image(r);
        
        return b;
    end function;
 
end package body random;