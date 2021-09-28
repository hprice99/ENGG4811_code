----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 07/05/2021 09:08:38 PM
-- Design Name: 
-- Module Name: top_tb - Behavioral
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

library xil_defaultlib;
use xil_defaultlib.fox_defs.all;
use xil_defaultlib.firmware_config.all;

entity top_tb is
end top_tb;

architecture Behavioral of top_tb is

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
            
            LED                 : out STD_LOGIC;
            
            out_char            : out std_logic_vector(7 downto 0);
            out_char_en         : out std_logic;
            
            uart_tx             : out std_logic;
            
            out_matrix          : out std_logic_vector(31 downto 0);
            out_matrix_en       : out std_logic;
            out_matrix_end_row  : out std_logic;
            out_matrix_end      : out std_logic
        );
    end component top_single_core;
    
    component UART is
        Generic (
            CLK_FREQ      : integer := 50e6;   -- system clock frequency in Hz
            BAUD_RATE     : integer := 115200; -- baud rate value
            PARITY_BIT    : string  := "none"; -- type of parity: "none", "even", "odd", "mark", "space"
            USE_DEBOUNCER : boolean := True    -- enable/disable debouncer
        );
        Port (
            -- CLOCK AND RESET
            CLK          : in  std_logic; -- system clock
            RST          : in  std_logic; -- high active synchronous reset
            -- UART INTERFACE
            UART_TXD     : out std_logic; -- serial transmit data
            UART_RXD     : in  std_logic; -- serial receive data
            -- USER DATA INPUT INTERFACE
            DIN          : in  std_logic_vector(7 downto 0); -- input data to be transmitted over UART
            DIN_VLD      : in  std_logic; -- when DIN_VLD = 1, input data (DIN) are valid
            DIN_RDY      : out std_logic; -- when DIN_RDY = 1, transmitter is ready and valid input data will be accepted for transmiting
            -- USER DATA OUTPUT INTERFACE
            DOUT         : out std_logic_vector(7 downto 0); -- output data received via UART
            DOUT_VLD     : out std_logic; -- when DOUT_VLD = 1, output data (DOUT) are valid (is assert only for one clock cycle)
            FRAME_ERROR  : out std_logic; -- when FRAME_ERROR = 1, stop bit was invalid (is assert only for one clock cycle)
            PARITY_ERROR : out std_logic  -- when PARITY_ERROR = 1, parity bit was invalid (is assert only for one clock cycle)
        );
    end component UART;
    
    signal clk          : std_logic := '0';
    constant clk_period : time := 10 ns;
    
    signal reset_n      : std_logic;
    signal reset        : std_logic;

    signal LED      : std_logic;
    
    signal count    : integer;
    
    signal uart_tx  : std_logic;
    
    signal uart_rx  : std_logic;
    signal uart_rx_char         : std_logic_vector(7 downto 0);
    signal uart_rx_char_valid   : std_logic;
    
    constant CLK_FREQ   : integer := 100e6;
    constant BAUD_RATE  : integer := 115200;
    constant PARITY_BIT : string := "none";
    constant USE_DEBOUNCER  : boolean := True;

    signal out_char     : std_logic_vector(7 downto 0);
    signal out_char_en  : std_logic;
    signal line_started : std_logic;

    signal out_matrix           : std_logic_vector(31 downto 0);
    signal out_matrix_en        : std_logic;
    signal out_matrix_end_row   : std_logic;
    signal out_matrix_end       : std_logic;

begin

    -- Generate clk and reset_n
    reset_n <= '0', '1' after 100*clk_period;
    
    reset   <= not reset_n;

    CLK_PROCESS: process
    begin
        clk <= '0';
        wait for clk_period/2;
        clk <= '1';
        wait for clk_period/2;
    end process CLK_PROCESS;

    COUNTER: process (clk)
    begin
        if (rising_edge(clk)) then
            if (reset_n = '0') then
                count   <= 0;
            else
                count   <= count + 1;
            end if;
        end if;
    end process COUNTER;

    SINGLE_CORE_TOP: top_single_core
        generic map (            
            FIRMWARE            => FOX_FIRMWARE,
            FIRMWARE_MEM_SIZE   => FOX_MEM_SIZE,
            
            CLK_FREQ            => CLK_FREQ,
            ENABLE_UART         => True
        )
        port map (
            clk                 => clk,
            reset_n             => reset_n,
            
            LED                 => LED,
            
            out_char            => out_char,
            out_char_en         => out_char_en,
            
            uart_tx             => uart_rx,
            
            out_matrix          => open,
            out_matrix_en       => open,
            out_matrix_end_row  => open,
            out_matrix_end      => open
        );
 
    -- Generate prints
    PRINT_OUTPUT: process (clk)
        variable my_output_line : line;
        variable my_file_line   : line;
        
        constant my_file_name : string := "top_tb.txt";
        file WriteFile : TEXT open WRITE_MODE is my_file_name;
    begin
        if (rising_edge(clk)) then
            if (reset_n = '0') then
                line_started    <= '0';
            else
                if (out_char_en = '1') then
                    if (character'val(to_integer(unsigned(out_char))) = LF) then
                        writeline(output, my_output_line);
                        writeline(WriteFile, my_file_line);
                        
                        line_started    <= '0';
                    else
                        if (line_started = '0') then
                            write(my_output_line, string'("Cycle count = "));
                            write(my_output_line, count);
                            write(my_output_line, string'(": "));
                            
                            write(my_file_line, string'("Cycle count = "));
                            write(my_file_line, count);
                            write(my_file_line, string'(": "));
                        end if;
                        
                        line_started    <= '1';
                        
                        write(my_output_line, character'val(to_integer(unsigned(out_char))));
                        write(my_file_line, character'val(to_integer(unsigned(out_char))));
                    end if;
                end if;
                
                if (out_matrix_en = '1') then
                    write(my_output_line, to_integer(unsigned(out_matrix)));
                    write(my_output_line, string'(" "));
                    
                    write(my_file_line, to_integer(unsigned(out_matrix)));
                    write(my_file_line, string'(" "));
                end if;
                
                if (out_matrix_end_row = '1') then
                    write(my_output_line, string'(" ," & LF));
                    write(my_file_line, string'(" ," & LF));
                end if;
            end if;
        end if;
    end process PRINT_OUTPUT;

end Behavioral;
