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
use IEEE.math_real.all;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

library xil_defaultlib;
use xil_defaultlib.firmware_config.all;
use xil_defaultlib.fox_defs.all;

entity board_top is
    Port ( 
           CPU_RESETN   : in STD_LOGIC;
           clk          : in STD_LOGIC;
           UART_RXD_OUT : out std_logic
    );
end board_top;

architecture Behavioral of board_top is

    component top_single_core
        generic (            
            FIRMWARE            : string := "firmware_single_core.hex";
            FIRMWARE_MEM_SIZE   : integer := 4096; 
            
            CLK_FREQ            : integer := 50e6;
            ENABLE_UART         : boolean := False
        );
        port (
            clk                 : in std_logic;
            reset_n             : in std_logic;

            out_char            : out std_logic_vector(7 downto 0);
            out_char_en         : out std_logic;
            
            uart_tx             : out std_logic;
            
            out_matrix          : out std_logic_vector(31 downto 0);
            out_matrix_en       : out std_logic;
            out_matrix_end_row  : out std_logic;
            out_matrix_end      : out std_logic;
            
            matrix_multiply_done : out std_logic
        );
    end component top_single_core;
    
    component clock_divider 
        Port ( 
            CLK_50MHZ   : out STD_LOGIC;
            reset       : in STD_LOGIC;
            locked      : out STD_LOGIC;
            clk_in1     : in STD_LOGIC
        );
    end component clock_divider;
        
    signal reset    : std_logic;
    signal locked   : std_logic;
        
    signal clkdiv2  : std_logic;
        
    constant CLK_FREQ       : integer := 50e6;
    constant ENABLE_UART    : boolean := True;
    
    signal reset_n  : std_logic;

begin

    reset   <= not CPU_RESETN;

    -- Clock divider
    DIVIDER: clock_divider
        port map (
            clk_in1     => clk,
            reset       => reset,
            locked      => locked,
            CLK_50MHZ   => clkdiv2
        );
    
    reset_n <= CPU_RESETN and locked;

    SINGLE_CORE_TOP: top_single_core
        generic map (            
            FIRMWARE            => FOX_FIRMWARE,
            FIRMWARE_MEM_SIZE   => FOX_MEM_SIZE,
            
            CLK_FREQ            => CLK_FREQ,
            ENABLE_UART         => ENABLE_UART
        )
        port map (
            clk                 => clkdiv2,
            reset_n             => reset_n,

            out_char            => open,
            out_char_en         => open,
            
            uart_tx             => UART_RXD_OUT,
            
            out_matrix          => open,
            out_matrix_en       => open,
            out_matrix_end_row  => open,
            out_matrix_end      => open,
            
            matrix_multiply_done    => open
        );

end Behavioral;
