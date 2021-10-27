library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use ieee.std_logic_unsigned.all;
use IEEE.math_real.all;

library xil_defaultlib;
use xil_defaultlib.math_functions.all;
use xil_defaultlib.firmware_config.all;
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
            
            FOX_FIRMWARE            : string := "firmware_hoplite.hex";
            FOX_FIRMWARE_MEM_SIZE   : integer := 4096; 
            
            RESULT_FIRMWARE             : string := "firmware_hoplite_result.hex";
            RESULT_FIRMWARE_MEM_SIZE    : integer := 8192;
            
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
            
            out_matrix          : out t_MatrixOut;
            out_matrix_en       : out t_MessageValid;
            out_matrix_end_row  : out t_MessageValid;
            out_matrix_end      : out t_MessageValid
        );
    end component top;
    
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

    FOX_TOP: top
        generic map (
            FOX_NETWORK_STAGES  => FOX_NETWORK_STAGES,
            FOX_NETWORK_NODES   => FOX_NETWORK_NODES,
            
            FOX_FIRMWARE            => FOX_FIRMWARE,
            FOX_FIRMWARE_MEM_SIZE   => FOX_MEM_SIZE,
            
            RESULT_FIRMWARE             => RESULT_FIRMWARE,
            RESULT_FIRMWARE_MEM_SIZE    => RESULT_MEM_SIZE,
            
            CLK_FREQ            => CLK_FREQ,
            ENABLE_UART         => ENABLE_UART
        )
        port map (
            clk                 => clkdiv2,
            reset_n             => reset_n,
            
            LED                 => LED,
            
            out_char            => open,
            out_char_en         => open,
            
            uart_tx             => UART_RXD_OUT,
            
            out_matrix          => open,
            out_matrix_en       => open,
            out_matrix_end_row  => open
        );

end Behavioral;
