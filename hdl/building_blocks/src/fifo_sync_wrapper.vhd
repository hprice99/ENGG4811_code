----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 08/11/2021 08:54:33 PM
-- Design Name: 
-- Module Name: fifo_sync_wrapper - Behavioral
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

entity fifo_sync_wrapper is
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
end fifo_sync_wrapper;

architecture Behavioral of fifo_sync_wrapper is

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
    
    component fifo_sync
        generic (
            BUS_WIDTH   : integer := 32;
            FIFO_DEPTH  : integer := 64
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
    end component fifo_sync;

begin

    UNINITIALISED_FIFO_GEN: if (INITIALISATION_FILE = "none") generate
        UNINITIALISED_FIFO: fifo_sync
            generic map (
                BUS_WIDTH   => BUS_WIDTH,
                FIFO_DEPTH  => FIFO_DEPTH
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
    end generate UNINITIALISED_FIFO_GEN;

    INITIALISED_FIFO_GEN: if (INITIALISATION_FILE /= "none") generate
        INITIALISED_FIFO: fifo_sync_memory_initialise
            generic map (
                BUS_WIDTH   => BUS_WIDTH,
                FIFO_DEPTH  => FIFO_DEPTH,
                
                INITIALISATION_FILE     => INITIALISATION_FILE,
                INITIALISATION_LENGTH   => INITIALISATION_LENGTH
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
    end generate INITIALISED_FIFO_GEN;

end Behavioral;
