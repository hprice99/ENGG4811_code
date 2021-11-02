library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.std_logic_textio.all;

use STD.textio.all;

library xil_defaultlib;
use xil_defaultlib.fox_defs.all;
use xil_defaultlib.packet_defs.all;
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
            
            out_matrix          : out t_MatrixOut;
            out_matrix_en       : out t_MessageValid;
            out_matrix_end_row  : out t_MessageValid;
            out_matrix_end      : out t_MessageValid;
            
            ila_multicast_in_1                : out std_logic_vector((BUS_WIDTH-1) downto 0);
            ila_multicast_in_1_valid          : out std_logic;
           
            ila_x_in_1            : out std_logic_vector((BUS_WIDTH-1) downto 0);
            ila_x_in_1_valid      : out std_logic;
           
            ila_y_in_1            : out std_logic_vector((BUS_WIDTH-1) downto 0);
            ila_y_in_1_valid      : out std_logic;
           
            ila_multicast_out_2                : out std_logic_vector((BUS_WIDTH-1) downto 0);
            ila_multicast_out_2_valid          : out std_logic;
           
            ila_x_out_2            : out std_logic_vector((BUS_WIDTH-1) downto 0);
            ila_x_out_2_valid      : out std_logic;
           
            ila_y_out_2            : out std_logic_vector((BUS_WIDTH-1) downto 0);
            ila_y_out_2_valid      : out std_logic
        );
    end component top;
    
    component UART is
        Generic (
            CLK_FREQ      : integer := 50e6;
            BAUD_RATE     : integer := 115200;
            PARITY_BIT    : string  := "none";
            USE_DEBOUNCER : boolean := True
        );
        Port (
            CLK          : in  std_logic;
            RST          : in  std_logic;
            UART_TXD     : out std_logic;
            UART_RXD     : in  std_logic;
            DIN          : in  std_logic_vector(7 downto 0);
            DIN_VLD      : in  std_logic;
            DIN_RDY      : out std_logic;
            DOUT         : out std_logic_vector(7 downto 0);
            DOUT_VLD     : out std_logic;
            FRAME_ERROR  : out std_logic;
            PARITY_ERROR : out std_logic
        );
    end component UART;
    
    signal clk          : std_logic := '0';
    constant clk_period : time := 10 ns;
    
    signal reset_n      : std_logic;
    signal reset        : std_logic;
    
--    constant FOX_FIRMWARE       : string := "firmware_fox_hoplite_multicast_tb.hex";
--    constant RESULT_FIRMWARE    : string := "firmware_fox_hoplite_multicast_result_tb.hex";
    
    constant FOX_FIRMWARE       : string := "firmware_fox_hoplite_multicast.hex";
    constant RESULT_FIRMWARE    : string := "firmware_fox_hoplite_multicast_result.hex";
    
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

    signal out_matrix           : t_MatrixOut;
    signal out_matrix_en        : t_MessageValid;
    signal out_matrix_end_row   : t_MessageValid;
    signal out_matrix_end       : t_MessageValid;
    
    signal ila_multicast_in_1                : std_logic_vector((BUS_WIDTH-1) downto 0);
    signal ila_multicast_in_1_valid          : std_logic;
           
    signal ila_x_in_1            : std_logic_vector((BUS_WIDTH-1) downto 0);
    signal ila_x_in_1_valid      : std_logic;
           
    signal ila_y_in_1            : std_logic_vector((BUS_WIDTH-1) downto 0);
    signal ila_y_in_1_valid      : std_logic;
           
    signal ila_multicast_out_2                : std_logic_vector((BUS_WIDTH-1) downto 0);
    signal ila_multicast_out_2_valid          : std_logic;
           
    signal ila_x_out_2            : std_logic_vector((BUS_WIDTH-1) downto 0);
    signal ila_x_out_2_valid      : std_logic;
           
    signal ila_y_out_2            : std_logic_vector((BUS_WIDTH-1) downto 0);
    signal ila_y_out_2_valid      : std_logic;

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
            out_matrix_end      => out_matrix_end,
            
            ila_multicast_in_1                => ila_multicast_in_1,
            ila_multicast_in_1_valid          => ila_multicast_in_1_valid,
           
            ila_x_in_1            => ila_x_in_1,
            ila_x_in_1_valid      => ila_x_in_1_valid,
           
            ila_y_in_1            => ila_y_in_1,
            ila_y_in_1_valid      => ila_y_in_1_valid,
           
            ila_multicast_out_2                => ila_multicast_out_2,
            ila_multicast_out_2_valid          => ila_multicast_out_2_valid,
           
            ila_x_out_2            => ila_x_out_2,
            ila_x_out_2_valid      => ila_x_out_2_valid,
           
            ila_y_out_2            => ila_y_out_2,
            ila_y_out_2_valid      => ila_y_out_2_valid
        );

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
