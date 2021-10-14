library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use ieee.math_real.all;

package math_functions is 
        
    function ceil_log2 (Arg : in positive)
    	return integer;
       
    function max(arg1, arg2 : in integer)
        return integer;
       
end package math_functions;

package body math_functions is
 
    function ceil_log2 (Arg : positive) return integer is
        variable i  : integer := 0;
    begin
        while (Arg > (2 ** i)) loop
            i := i + 1;
        end loop;
        
        return i;
    end function ceil_log2;
    
    function max(arg1, arg2 : integer) return integer is
    begin
        if (arg1 > arg2) then
            return arg1;
        else
            return arg2;
        end if;
    end function max;
 
end package body math_functions;
