library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

library xil_defaultlib;
use xil_defaultlib.math_functions.all;

package matrix_config is 

    -- Matrix parameters
    -- Matrix has dimensions (TOTAL_MATRIX_SIZE * TOTAL_MATRIX_SIZE)
    constant TOTAL_MATRIX_SIZE      : integer := 4;
    constant TOTAL_MATRIX_ELEMENTS  : integer := (TOTAL_MATRIX_SIZE ** 2);
    
    -- Each processor operates on a (FOX_MATRIX_SIZE * FOX_MATRIX_SIZE) matrix
    constant FOX_MATRIX_SIZE     : integer := 2;
    constant FOX_MATRIX_ELEMENTS : integer := (FOX_MATRIX_SIZE ** 2);

end package matrix_config;

package body matrix_config is

end package body matrix_config;