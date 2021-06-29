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
use IEEE.NUMERIC_STD.ALL;
use IEEE.math_real.all;

use STD.textio.all;
use IEEE.std_logic_textio.all;

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
        count                : in integer;
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

    type t_Coordinate is array (0 to 1) of std_logic_vector((COORD_BITS-1) downto 0);
    constant X_INDEX    : integer := 0;
    constant Y_INDEX    : integer := 1;

    constant x_src : std_logic_vector((COORD_BITS-1) downto 0) := std_logic_vector(to_unsigned(X_COORD, COORD_BITS));
    constant y_src : std_logic_vector((COORD_BITS-1) downto 0) := std_logic_vector(to_unsigned(Y_COORD, COORD_BITS));

    constant src : t_Coordinate := (X_INDEX => x_src, Y_INDEX => y_src);
    signal dest : t_Coordinate;

    signal message : std_logic_vector((BUS_WIDTH-1) downto 0);
    
    signal received_src, received_dest : t_Coordinate;

begin

    dest(X_INDEX) <= x_dest; 
    dest(Y_INDEX) <= y_dest;

    -- Message format 0 -- x_dest | y_dest | x_src | y_src -- (BUS_WIDTH-1)
    message <=  src(Y_INDEX) & src(X_INDEX) & dest(Y_INDEX) & dest(X_INDEX);

    MESSAGE_OUT_FF : process (clk)
    begin
        if (rising_edge(clk)) then
            if (reset_n = '0' or trig = '0') then
                message_out         <= (others => '0');
                message_out_valid   <= '0';
            elsif (trig = '1') then
                message_out         <= message;
                message_out_valid   <= '1';
            end if;
        end if;
    end process MESSAGE_OUT_FF;

    -- Print message_in to stdout if it is valid
    received_src(Y_INDEX) <= message_in((4*COORD_BITS-1) downto 3*COORD_BITS);
    received_src(X_INDEX) <= message_in((3*COORD_BITS-1) downto 2*COORD_BITS);
    received_dest(Y_INDEX) <= message_in((2*COORD_BITS-1) downto COORD_BITS);
    received_dest(X_INDEX) <= message_in((COORD_BITS-1) downto 0);
    
    MESSAGE_RECEIVED: process (clk)
        variable my_line : line;
    begin
        if (rising_edge(clk) and reset_n = '1' and message_in_valid = '1') then
            write(my_line, string'(HT & "hoplite_tb_pe: "));
        
            write(my_line, string'("Node ("));
            write(my_line, X_COORD);
            
            write(my_line, string'(", "));
            write(my_line, Y_COORD);
            write(my_line, string'(")"));
            
            write(my_line, string'(", Cycle Count = "));
            write(my_line, count);
            
            writeline(output, my_line);
        
            write(my_line, string'(HT & HT & "Source X = "));
            write(my_line, to_integer(unsigned(received_src(X_INDEX))));
            
            write(my_line, string'(", Source Y = "));
            write(my_line, to_integer(unsigned(received_src(Y_INDEX))));
            
            write(my_line, string'(", Destination X = "));
            write(my_line, to_integer(unsigned(received_dest(X_INDEX))));
            
            write(my_line, string'(", Destination Y = "));
            write(my_line, to_integer(unsigned(received_dest(Y_INDEX))));
            
            writeline(output, my_line);
        end if;
    end process MESSAGE_RECEIVED;
    
end Behavioral;
