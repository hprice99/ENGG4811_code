----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 03/31/2021 07:24:23 PM
-- Design Name: 
-- Module Name: top - Behavioral
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
use ieee.std_logic_unsigned.all;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

library xil_defaultlib;
use xil_defaultlib.packet_defs.all;
use xil_defaultlib.fox_defs.all;
use xil_defaultlib.matrix_config.all;
use xil_defaultlib.firmware_config.all;

entity top_single_core is
    generic (            
        FIRMWARE            : string := "firmware_single_core.hex";
        FIRMWARE_MEM_SIZE   : integer := 4096; 
        
        CLK_FREQ            : integer := 50e6;
        ENABLE_UART         : boolean := False
    );
    port (
        clk                 : in std_logic;
        reset_n             : in std_logic;
        
        LED                 : out STD_LOGIC;
        
        out_char            : out std_logic_vector(7 downto 0);
        out_char_en         : out std_logic;
        
        uart_tx             : out std_logic;
        
        out_matrix          : out std_logic_vector(31 downto 0);
        out_matrix_en       : out std_logic;
        out_matrix_end_row  : out std_logic;
        out_matrix_end      : out std_logic
    );
end top_single_core;

architecture Behavioral of top_single_core is

    component system_single_core
        generic (
             DIVIDE_ENABLED     : std_logic := '0';
             MULTIPLY_ENABLED   : std_logic := '1';
             FIRMWARE           : string    := "firmware.hex";
             MEM_SIZE           : integer   := 4096
        );
        port (
            clk                     : in std_logic;
            reset_n                 : in std_logic;
            
            LED                     : out std_logic;
            
            out_char                : out std_logic_vector(7 downto 0);
            out_char_en             : out std_logic;
            out_char_ready          : in std_logic;
            
            matrix_type_in          : in std_logic_vector((MATRIX_TYPE_BITS-1) downto 0);
            matrix_x_coord_in       : in std_logic_vector((MATRIX_COORD_BITS-1) downto 0);
            matrix_y_coord_in       : in std_logic_vector((MATRIX_COORD_BITS-1) downto 0);
            matrix_element_in       : in std_logic_vector((MATRIX_ELEMENT_BITS-1) downto 0);
            message_in_valid        : in std_logic;
            message_in_available    : in std_logic;
            message_in_read         : out std_logic;
            
            out_matrix              : out std_logic_vector(31 downto 0);
            out_matrix_en           : out std_logic;
            out_matrix_end_row      : out std_logic;
            out_matrix_end          : out std_logic
        );
    end component system_single_core;
    
    constant divide_parameter   : std_logic := '1';
    constant multiply_parameter : std_logic := '1';
    
    component pipeline
        generic (
            STAGES  : integer := 10
        );
        port (
            clk     : in STD_LOGIC;
            d_in    : in STD_LOGIC;
            d_out   : out STD_LOGIC
        );
    end component pipeline;
    
    signal uart_tx_ready   : std_logic;
    
    signal matrix_type_in          : std_logic_vector((MATRIX_TYPE_BITS-1) downto 0);
    signal matrix_x_coord_in       : std_logic_vector((MATRIX_COORD_BITS-1) downto 0);
    signal matrix_y_coord_in       : std_logic_vector((MATRIX_COORD_BITS-1) downto 0);
    signal matrix_element_in       : std_logic_vector((MATRIX_ELEMENT_BITS-1) downto 0);
    signal message_in_valid        : std_logic;
    signal message_in_available    : std_logic;
    signal message_in_read         : std_logic;

begin

    -- TODO Connect to UART
    uart_tx_ready  <= '1';

    CORE : system_single_core
        generic map(
           DIVIDE_ENABLED   => divide_parameter,
           MULTIPLY_ENABLED => multiply_parameter,
           FIRMWARE         => FOX_FIRMWARE,
           MEM_SIZE         => FOX_MEM_SIZE
        )
        port map (
            clk                         => clk,
            reset_n                     => reset_n,

            LED                         => LED,
            
            out_char                    => out_char,
            out_char_en                 => out_char_en,
            out_char_ready              => uart_tx_ready,
            
            matrix_type_in          => matrix_type_in,
            matrix_x_coord_in       => matrix_x_coord_in,
            matrix_y_coord_in       => matrix_y_coord_in,
            matrix_element_in       => matrix_element_in,
            message_in_valid        => message_in_valid,
            message_in_available    => message_in_available,
            message_in_read         => message_in_read,
            
            out_matrix_en               => open,
            out_matrix                  => open,
            out_matrix_end_row          => open,
            out_matrix_end              => open
        );

end Behavioral;
