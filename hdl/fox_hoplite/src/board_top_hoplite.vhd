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
use xil_defaultlib.math_functions.all;
use xil_defaultlib.fox_defs.all;

entity board_top is
    Port ( 
           CPU_RESETN   : in STD_LOGIC;
           clk          : in STD_LOGIC;
           LED          : out STD_LOGIC_VECTOR(3 downto 0);
           UART_RXD_OUT : out std_logic
    );
end board_top;

architecture Behavioral of board_top is

    component top
        generic (
            -- Fox's algorithm network paramters
            FOX_NETWORK_STAGES  : integer := 2;
            FOX_NETWORK_NODES   : integer := 4;
            
            CLK_FREQ            : integer := 50e6;
            ENABLE_UART         : boolean := False
        );
        port (
            clk                 : in std_logic;
            reset_n             : in std_logic;
            
            LED                 : out STD_LOGIC_VECTOR((FOX_NETWORK_NODES-1) downto 0);
            
            out_char            : out t_Char;
            out_char_en         : out t_MessageValid;
            
            uart_tx             : out std_logic;
            
            out_matrix          : out t_Matrix;
            out_matrix_en       : out t_MessageValid;
            out_matrix_end_row  : out t_MessageValid;
            out_matrix_end      : out t_MessageValid
        );
    end component top;
    
    signal clkdiv2  : std_logic := '0';
    
    constant CLK_FREQ       : integer := 50e6;
    constant ENABLE_UART    : boolean := True;

begin

    -- Clock divider
    CLOCK_DIVIDER: process (clk)
    begin
        if (rising_edge(clk)) then   
            clkdiv2 <= not clkdiv2;
        end if;
    end process CLOCK_DIVIDER;

    FOX_TOP: top
        generic map (
            FOX_NETWORK_STAGES  => FOX_NETWORK_STAGES,
            FOX_NETWORK_NODES   => FOX_NETWORK_NODES,
            
            CLK_FREQ            => CLK_FREQ,
            ENABLE_UART         => ENABLE_UART
        )
        port map (
            clk                 => clkdiv2,
            reset_n             => CPU_RESETN,
            
            LED                 => LED,
            
            out_char            => open,
            out_char_en         => open,
            
            uart_tx             => UART_RXD_OUT,
            
            out_matrix          => open,
            out_matrix_en       => open,
            out_matrix_end_row  => open,
            out_matrix_end      => open
        );

end Behavioral;
