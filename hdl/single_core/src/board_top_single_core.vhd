library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

use IEEE.NUMERIC_STD.ALL;
use ieee.std_logic_unsigned.all;
use IEEE.math_real.all;

library xil_defaultlib;
use xil_defaultlib.firmware_config.all;
use xil_defaultlib.fox_defs.all;

entity board_top is
    Port ( 
           CPU_RESETN   : in std_logic;
           clk          : in std_logic;
           LED          : out std_logic_vector(0 downto 0);
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
            
            LED                 : out std_logic;
            
            out_char            : out std_logic_vector(7 downto 0);
            out_char_en         : out std_logic;
            
            uart_tx             : out std_logic;
            
            out_matrix          : out std_logic_vector(31 downto 0);
            out_matrix_en       : out std_logic;
            out_matrix_end_row  : out std_logic;
            out_matrix_end      : out std_logic
        );
    end component top_single_core;
    
    component clock_divider 
        Port ( 
            CLK_50MHZ   : out std_logic;
            reset       : in std_logic;
            locked      : out std_logic;
            clk_in1     : in std_logic
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
            
            LED                 => LED(0),
            
            out_char            => open,
            out_char_en         => open,
            
            uart_tx             => UART_RXD_OUT,
            
            out_matrix          => open,
            out_matrix_en       => open,
            out_matrix_end_row  => open,
            out_matrix_end      => open
        );

end Behavioral;
