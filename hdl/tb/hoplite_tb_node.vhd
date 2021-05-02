----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 05/01/2021 07:14:16 PM
-- Design Name: 
-- Module Name: hoplite_tb_node - Behavioral
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

use STD.textio.all;
use IEEE.std_logic_textio.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity hoplite_tb_node is
    Generic (
        X_COORD     : integer := 0;
        Y_COORD     : integer := 0;
        COORD_BITS  : integer := 2;
        BUS_WIDTH   : integer := 8
    );
    Port ( 
        clk                 : in STD_LOGIC;
        reset_n             : in STD_LOGIC;
        x_dest              : in STD_LOGIC_VECTOR((COORD_BITS-1) downto 0);
        y_dest              : in STD_LOGIC_VECTOR((COORD_BITS-1) downto 0);
        trig                : in STD_LOGIC;
        x_in                : in STD_LOGIC_VECTOR((BUS_WIDTH-1) downto 0);
        x_in_valid          : in STD_LOGIC;
        y_in                : in STD_LOGIC_VECTOR((BUS_WIDTH-1) downto 0);
        y_in_valid          : in STD_LOGIC;
        x_out               : out STD_LOGIC_VECTOR((BUS_WIDTH-1) downto 0);
        x_out_valid         : out STD_LOGIC;
        y_out               : out STD_LOGIC_VECTOR((BUS_WIDTH-1) downto 0);
        y_out_valid         : out STD_LOGIC
    );
end hoplite_tb_node;

architecture Behavioral of hoplite_tb_node is

    component hoplite_router
        generic (
            BUS_WIDTH   : integer := 32;
            X_COORD     : integer := 0;
            Y_COORD     : integer := 0;
            COORD_BITS  : integer := 1
        );
        port (
            clk             : in STD_LOGIC;
            reset_n         : in STD_LOGIC;
            x_in            : in STD_LOGIC_VECTOR((BUS_WIDTH-1) downto 0);
            x_in_valid      : in STD_LOGIC;
            y_in            : in STD_LOGIC_VECTOR((BUS_WIDTH-1) downto 0);
            y_in_valid      : in STD_LOGIC;
            pe_in           : in STD_LOGIC_VECTOR((BUS_WIDTH-1) downto 0);
            pe_in_valid     : in STD_LOGIC;
            x_out           : out STD_LOGIC_VECTOR((BUS_WIDTH-1) downto 0);
            x_out_valid     : out STD_LOGIC;
            y_out           : out STD_LOGIC_VECTOR((BUS_WIDTH-1) downto 0);
            y_out_valid     : out STD_LOGIC;
            pe_out          : out STD_LOGIC_VECTOR((BUS_WIDTH-1) downto 0);
            pe_out_valid    : out STD_LOGIC;
            pe_backpressure : out STD_LOGIC
        );
    end component hoplite_router;

    component hoplite_tb_pe
        generic (
            BUS_WIDTH   : integer := 32;
            X_COORD     : integer := 0;
            Y_COORD     : integer := 0;
            COORD_BITS  : integer := 1
        );
        port (
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
    end component hoplite_tb_pe; 
    
    signal pe_message_out       : STD_LOGIC_VECTOR ((BUS_WIDTH-1) downto 0);
    signal pe_message_out_valid : STD_LOGIC;
    
    signal pe_message_in       : STD_LOGIC_VECTOR ((BUS_WIDTH-1) downto 0);
    signal pe_message_in_valid : STD_LOGIC;
    
    signal x_out_buf, y_out_buf : STD_LOGIC_VECTOR ((BUS_WIDTH-1) downto 0);
    signal x_out_valid_buf, y_out_valid_buf : STD_LOGIC;

begin

    ROUTER: hoplite_router
        generic map (
            BUS_WIDTH   => BUS_WIDTH,
            X_COORD     => X_COORD,
            Y_COORD     => Y_COORD,
            COORD_BITS  => COORD_BITS
        )
        port map (
            clk                 => clk,
            reset_n             => reset_n,
            x_in                => x_in,
            x_in_valid          => x_in_valid,
            y_in                => y_in,
            y_in_valid          => y_in_valid,
            pe_in               => pe_message_out,
            pe_in_valid         => pe_message_out_valid,
            x_out               => x_out_buf,
            x_out_valid         => x_out_valid_buf,
            y_out               => y_out_buf,
            y_out_valid         => y_out_valid_buf,
            pe_out              => pe_message_in,
            pe_out_valid        => pe_message_in_valid,
            pe_backpressure     => open
        );
       
    PRINT: process (clk)
        variable my_line : line;
        begin
            if (rising_edge(clk)) then
                if (x_in_valid = '1') then
                    write(my_line, string'("("));
                    write(my_line, X_COORD);
                    
                    write(my_line, string'(", "));
                    write(my_line, Y_COORD);
                    
                    write(my_line, string'("), x_in: "));
                    write(my_line, x_in);
                    
                    writeline(output, my_line);
                end if;
                
                if (y_in_valid = '1') then
                    write(my_line, string'("("));
                    write(my_line, X_COORD);
                    
                    write(my_line, string'(", "));
                    write(my_line, Y_COORD);
                    
                    write(my_line, string'("), y_in: "));
                    write(my_line, y_in);
                    
                    writeline(output, my_line);
                end if;
                
                if (x_out_valid_buf = '1') then
                    write(my_line, string'("("));
                    write(my_line, X_COORD);
                    
                    write(my_line, string'(", "));
                    write(my_line, Y_COORD);
                    
                    write(my_line, string'("), x_out: "));
                    write(my_line, x_out_buf);
                    
                    writeline(output, my_line);
                end if;
                
                if (y_out_valid_buf = '1') then
                    write(my_line, string'("("));
                    write(my_line, X_COORD);
                    
                    write(my_line, string'(", "));
                    write(my_line, Y_COORD);
                    
                    write(my_line, string'("), y_out: "));
                    write(my_line, y_out_buf);
                    
                    writeline(output, my_line);
                end if;
            end if;
        end process PRINT;
    
    PE : hoplite_tb_pe
        generic map (
            BUS_WIDTH   => BUS_WIDTH,
            X_COORD     => X_COORD,
            Y_COORD     => Y_COORD,
            COORD_BITS  => COORD_BITS
        )
        port map (
            clk                 => clk,
            reset_n             => reset_n,
            trig                => trig,
            x_dest              => x_dest,
            y_dest              => y_dest,
            message_out         => pe_message_out,
            message_out_valid   => pe_message_out_valid,
            message_in          => pe_message_in,
            message_in_valid    => pe_message_in_valid
        );

end Behavioral;
