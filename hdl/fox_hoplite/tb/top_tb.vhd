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
            
            out_matrix          : out t_Matrix;
            out_matrix_en       : out t_MessageValid;
            out_matrix_end_row  : out t_MessageValid;
            out_matrix_end      : out t_MessageValid
        );
    end component top;
    
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
    
--    constant FOX_FIRMWARE       : string := "firmware_hoplite_tb.hex";
--    constant RESULT_FIRMWARE    : string := "firmware_hoplite_result_tb.hex";
    
--    constant FOX_FIRMWARE       : string := "firmware_hoplite.hex";
--    constant RESULT_FIRMWARE    : string := "firmware_hoplite_result.hex";
    
    signal LED      : std_logic_vector((FOX_NETWORK_NODES-1) downto 0);
    
    signal count    : integer;
    
    signal uart_tx  : std_logic;
    
    signal uart_rx  : std_logic;
    signal uart_rx_char         : std_logic_vector(7 downto 0);
    signal uart_rx_char_valid   : std_logic;
    
    constant CLK_FREQ   : integer := 100e6;
    constant BAUD_RATE  : integer := 115200;
    constant PARITY_BIT : string := "none";
    constant USE_DEBOUNCER  : boolean := True;

    signal out_char     : t_Char;
    signal out_char_en  : t_MessageValid;
    signal line_started : t_MessageValid;

    signal out_matrix           : t_Matrix;
    signal out_matrix_en        : t_MessageValid;
    signal out_matrix_end_row   : t_MessageValid;
    signal out_matrix_end       : t_MessageValid;

begin

    -- Generate clk and reset_n
    reset_n <= '0', '1' after 100*clk_period;
    
    reset   <= not reset_n;

    CLK_PROCESS: process
    begin
        clk <= '0';
        wait for clk_period/2;  --for 0.5 ns signal is '0'.
        clk <= '1';
        wait for clk_period/2;  --for next 0.5 ns signal is '1'.
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

    FOX_TOP: top
        generic map (
            FOX_NETWORK_STAGES  => FOX_NETWORK_STAGES,
            FOX_NETWORK_NODES   => FOX_NETWORK_NODES,
            
            FOX_FIRMWARE            => FOX_FIRMWARE,
            FOX_FIRMWARE_MEM_SIZE   => FOX_MEM_SIZE,
            
            RESULT_FIRMWARE             => RESULT_FIRMWARE,
            RESULT_FIRMWARE_MEM_SIZE    => RESULT_MEM_SIZE,
            
            CLK_FREQ            => CLK_FREQ,
            ENABLE_UART         => True
        )
        port map (
            clk                 => clk,
            reset_n             => reset_n,
            
            LED                 => LED,
            
            out_char            => out_char,
            out_char_en         => out_char_en,
            
            uart_tx             => uart_tx,
            
            out_matrix          => out_matrix,
            out_matrix_en       => out_matrix_en,
            out_matrix_end_row  => out_matrix_end_row,
            out_matrix_end      => out_matrix_end
        );
        
--    RX_BUFFER: process (clk)
--    begin
--        if (rising_edge(clk)) then
--            uart_rx <= uart_tx;
--        end if;
--    end process RX_BUFFER;
    
--    UART_RECEIVER: UART
--            generic map (
--                CLK_FREQ      => CLK_FREQ,
--                BAUD_RATE     => BAUD_RATE,
--                PARITY_BIT    => PARITY_BIT,
--                USE_DEBOUNCER => USE_DEBOUNCER
--            )
--            port map (
--                -- CLOCK AND RESET
--                CLK          => clk,
--                RST          => reset,

--                UART_TXD     => uart_tx,
--                UART_RXD     => uart_rx,
                
--                DIN          => (others => '1'), 
--                DIN_VLD      => '0', 
--                DIN_RDY      => open,

--                DOUT         => uart_rx_char,
--                DOUT_VLD     => uart_rx_char_valid, 
--                FRAME_ERROR  => open, 
--                PARITY_ERROR => open
--            );

    -- Generate prints for Fox's algorithm processing elements
    PRINT_OUTPUT_ROW_GEN: for i in 0 to (FOX_NETWORK_STAGES-1) generate
        PRINT_OUTPUT_COL_GEN: for j in 0 to (FOX_NETWORK_STAGES-1) generate
            constant curr_y         : integer := i;
            constant curr_x         : integer := j;
            constant node_number    : integer := i * FOX_NETWORK_STAGES + j;
        begin
            PRINT_OUTPUT: process (clk)
                variable my_output_line : line;
                variable my_file_line   : line;
                
                constant my_file_name : string := "Node " & integer'image(node_number) & ".txt";
                file WriteFile : TEXT open WRITE_MODE is my_file_name;
            begin
                if (rising_edge(clk)) then
                    if (reset_n = '0') then
                        line_started(curr_x, curr_y)    <= '0';
                    else
                        if (out_char_en(curr_x, curr_y) = '1') then
                            if (character'val(to_integer(unsigned(out_char(curr_x, curr_y)))) = LF) then
                                writeline(output, my_output_line);
                                writeline(WriteFile, my_file_line);
                                
                                line_started(curr_x, curr_y)    <= '0';
                            else
                                if (line_started(curr_x, curr_y) = '0') then
                                    write(my_output_line, string'("Cycle count = "));
                                    write(my_output_line, count);
                                    write(my_output_line, string'(", "));
                                    write(my_output_line, string'("Node number = "));
                                    write(my_output_line, node_number);
                                    write(my_output_line, string'(": "));
                                    
                                    write(my_file_line, string'("Cycle count = "));
                                    write(my_file_line, count);
                                    write(my_file_line, string'(", "));
                                    write(my_file_line, string'("Node number = "));
                                    write(my_file_line, node_number);
                                    write(my_file_line, string'(": "));
                                end if;
                                
                                line_started(curr_x, curr_y)    <= '1';
                                
                                write(my_output_line, character'val(to_integer(unsigned(out_char(curr_x, curr_y)))));
                                write(my_file_line, character'val(to_integer(unsigned(out_char(curr_x, curr_y)))));
                            end if;
                        end if;
                        
                        if (out_matrix_en(curr_x, curr_y) = '1') then
                            write(my_output_line, to_integer(unsigned(out_matrix(curr_x, curr_y))));
                            write(my_output_line, string'(" "));
                            
                            write(my_file_line, to_integer(unsigned(out_matrix(curr_x, curr_y))));
                            write(my_file_line, string'(" "));
                        end if;
                        
                        if (out_matrix_end_row(curr_x, curr_y) = '1') then
                            write(my_output_line, string'(" ," & LF));
                            write(my_file_line, string'(" ," & LF));
                        end if;
                    end if;
                end if;
            end process PRINT_OUTPUT;
        end generate PRINT_OUTPUT_COL_GEN;
    end generate PRINT_OUTPUT_ROW_GEN;

end Behavioral;
