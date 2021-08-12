----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 08/11/2021 06:40:24 PM
-- Design Name: 
-- Module Name: fifo_sync_memory_initialise_tb - Behavioral
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
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

library xil_defaultlib;
use xil_defaultlib.math_functions.all;
use xil_defaultlib.fox_defs.all;

entity fifo_sync_memory_initialise_tb is
--  Port ( );
end fifo_sync_memory_initialise_tb;

architecture Behavioral of fifo_sync_memory_initialise_tb is

    signal clk          : std_logic;
    constant clk_period : time := 10 ns;
    
    signal reset_n  : std_logic;

    component fifo_sync_memory_initialise
        generic (
            BUS_WIDTH   : integer := 32;
            FIFO_DEPTH  : integer := 64;
            
            INITIALISATION_FILE     : string := "none";
            INITIALISATION_LENGTH   : integer := 0
        );
        port (
            clk         : in std_logic;
            reset_n     : in std_logic;
    
            write_en    : in std_logic;
            write_data  : in std_logic_vector((BUS_WIDTH-1) downto 0);
            
            read_en     : in std_logic;
            read_data   : out std_logic_vector((BUS_WIDTH-1) downto 0);
            
            full        : out std_logic;
            empty       : out std_logic
        );
    end component fifo_sync_memory_initialise;
    
    constant matrix_file : string := "matrix.txt";
    
    signal write_en     : std_logic;
    signal write_data   : std_logic_vector((BUS_WIDTH-1) downto 0);
    
    signal read_en      : std_logic;
    signal read_data    : std_logic_vector((BUS_WIDTH-1) downto 0);
    
    signal full         : std_logic;
    signal empty        : std_logic;
    
begin

    -- Generate clk and reset_n
    reset_n <= '0', '1' after clk_period;

    CLK_PROCESS: process
    begin
        clk <= '0';
        wait for clk_period/2;  --for 0.5 ns signal is '0'.
        clk <= '1';
        wait for clk_period/2;  --for next 0.5 ns signal is '1'.
    end process CLK_PROCESS;

    FIFO: fifo_sync_memory_initialise
        generic map (
            BUS_WIDTH   => BUS_WIDTH,
            FIFO_DEPTH  => FOX_FIFO_DEPTH,
            
            INITIALISATION_FILE     => matrix_file,
            INITIALISATION_LENGTH   => FOX_FIFO_DEPTH
        )
        port map (
            clk         => clk,
            reset_n     => reset_n,
            
            write_en    => write_en,
            write_data  => write_data,
            
            read_en     => read_en,
            read_data   => read_data,
            
            full        => full,
            empty       => empty
        );

end Behavioral;
