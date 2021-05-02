----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 05/01/2021 06:11:55 PM
-- Design Name: 
-- Module Name: hoplite_tb_pe - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

use STD.textio.all;
use IEEE.std_logic_textio.all;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity hoplite_tb_pe is
    Generic (
        X_COORD     : integer := 0;
        Y_COORD     : integer := 0;
        COORD_BITS  : integer := 2;
        BUS_WIDTH   : integer := 8
    );
    Port ( 
        clk                  : in STD_LOGIC;
        reset_n              : in STD_LOGIC;
        trig                 : in STD_LOGIC;
        x_dest               : in STD_LOGIC_VECTOR((COORD_BITS-1) downto 0);
        y_dest               : in STD_LOGIC_VECTOR((COORD_BITS-1) downto 0);
        message_out          : out STD_LOGIC_VECTOR ((BUS_WIDTH-1) downto 0);
        message_out_valid    : out STD_LOGIC;
        message_in           : in STD_LOGIC_VECTOR ((BUS_WIDTH-1) downto 0);
        message_in_valid     : in STD_LOGIC
   );
end hoplite_tb_pe;

architecture Behavioral of hoplite_tb_pe is

    constant x_src : std_logic_vector((COORD_BITS-1) downto 0) := std_logic_vector(to_unsigned(X_COORD, COORD_BITS));
    constant y_src : std_logic_vector((COORD_BITS-1) downto 0) := std_logic_vector(to_unsigned(Y_COORD, COORD_BITS));

    signal message : std_logic_vector((BUS_WIDTH-1) downto 0);
    
    signal received_x_src, received_y_src, received_x_dest, received_y_dest : std_logic_vector((COORD_BITS-1) downto 0);

begin

    message <=  y_src & x_src & y_dest & x_dest;

    MESSAGE_OUT_FF : process (clk)
        begin
            if (rising_edge(clk)) then
                if (reset_n = '0') then
                    message_out         <= (others => '0');
                    message_out_valid   <= '0';
                elsif (trig = '1') then
                    message_out         <= message;
                    message_out_valid   <= '1';
                end if;
            end if;
        end process MESSAGE_OUT_FF;

    -- Print message_in to stdout if it is valid
    received_y_src <= message_in((4*COORD_BITS-1) downto 3*COORD_BITS);
    received_x_src <= message_in((3*COORD_BITS-1) downto 2*COORD_BITS);
    received_y_dest <= message_in((2*COORD_BITS-1) downto COORD_BITS);
    received_x_dest <= message_in((COORD_BITS-1) downto 0);
    
    
    MESSAGE_RECEIVED: process (clk)
        variable my_line : line;
        begin
            if (rising_edge(clk) and message_in_valid = '1') then
                write(my_line, string'("Source X = "));
                write(my_line, received_x_src);
                
                write(my_line, string'(", Source Y = "));
                write(my_line, received_y_src);
                
                write(my_line, string'(", Destination X = "));
                write(my_line, received_x_dest);
                
                write(my_line, string'(", Destination Y = "));
                write(my_line, received_y_dest);
                
                writeline(output, my_line);
            end if;
        end process MESSAGE_RECEIVED;
    
end Behavioral;
