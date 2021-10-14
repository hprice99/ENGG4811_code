library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use ieee.math_real.all;

package conv_functions is 
        
    function int_to_slv (num : in integer ; width : in integer)
    	return std_logic_vector;
    	
    function slv_to_int (vect : in std_logic_vector)
        return integer;
       
end package conv_functions;

package body conv_functions is
 
    function int_to_slv (num : integer ; width : integer) return std_logic_vector is
        variable vect  : std_logic_vector((width-1) downto 0) := (others => '0');
    begin
        vect    := std_logic_vector(to_signed(num, width));
        
        return vect;
    end function int_to_slv;
    
    function slv_to_int (vect : in std_logic_vector) return integer is
        variable int : integer;
    begin
        int := to_integer(unsigned(vect));
        
        return int;
    end function slv_to_int;
 
end package body conv_functions;
