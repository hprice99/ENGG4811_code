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
use xil_defaultlib.math_functions.all;
use xil_defaultlib.fox_defs.all;

entity top is
    Generic (
        -- Fox's algorithm network paramters
        FOX_NETWORK_STAGES  : integer := 2;
        FOX_NETWORK_NODES   : integer := 4;
        
        CLK_FREQ            : integer := 50e6;
        ENABLE_UART         : boolean := False
    );
    Port ( 
           reset_n              : in STD_LOGIC;
           clk                  : in STD_LOGIC;
           
           LED                  : out STD_LOGIC_VECTOR((FOX_NETWORK_NODES-1) downto 0);
           
           out_char             : out t_Char;
           out_char_en          : out t_MessageValid;
           
           uart_tx             : out std_logic;
           
           out_matrix           : out t_Matrix;
           out_matrix_en        : out t_MessageValid;
           out_matrix_end_row   : out t_MessageValid;
           out_matrix_end       : out t_MessageValid
    );
end top;

architecture Behavioral of top is

    component fox_node
        generic (
            -- Entire network parameters
            NETWORK_ROWS    : integer := 2;
            NETWORK_COLS    : integer := 2;
            NETWORK_NODES   : integer := 4;

            -- Fox's algorithm network paramters
            FOX_NETWORK_STAGES  : integer := 2;
            FOX_NETWORK_NODES   : integer := 4;

            -- Result node parameters
            RESULT_X_COORD  : integer := 0;
            RESULT_Y_COORD  : integer := 2;
        
            -- Node parameters
            X_COORD         : integer := 0;
            Y_COORD         : integer := 0;
            NODE_NUMBER     : integer := 0;

            -- Packet parameters
            COORD_BITS              : integer := 2;
            MULTICAST_GROUP_BITS    : integer := 1;
            MATRIX_TYPE_BITS        : integer := 1;
            MATRIX_COORD_BITS       : integer := 8;
            MATRIX_ELEMENT_BITS     : integer := 32;
            BUS_WIDTH               : integer := 56;

            -- Matrix parameters
            TOTAL_MATRIX_SIZE   : integer := 32;
            FOX_MATRIX_SIZE     : integer := 16;
            MATRIX_FILE         : string  := "none";
            
            -- Matrix offset for node
            MATRIX_X_OFFSET : integer := 0;
            MATRIX_Y_OFFSET : integer := 0;

            -- NIC parameters
            FIFO_DEPTH      : integer := 32;
            
            -- PicoRV32 core parameters
            DIVIDE_ENABLED     : std_logic := '0';
            MULTIPLY_ENABLED   : std_logic := '1';
            FIRMWARE           : string    := "firmware.hex";
            MEM_SIZE           : integer   := 4096
        );
        port (
            clk                 : in std_logic;
            reset_n             : in std_logic;

            LED                 : out std_logic;

            out_char            : out std_logic_vector(7 downto 0);
            out_char_en         : out std_logic;
            
            x_in                : in STD_LOGIC_VECTOR((BUS_WIDTH-1) downto 0);
            x_in_valid          : in STD_LOGIC;
            y_in                : in STD_LOGIC_VECTOR((BUS_WIDTH-1) downto 0);
            y_in_valid          : in STD_LOGIC;
            
            x_out               : out STD_LOGIC_VECTOR((BUS_WIDTH-1) downto 0);
            x_out_valid         : out STD_LOGIC;
            y_out               : out STD_LOGIC_VECTOR((BUS_WIDTH-1) downto 0);
            y_out_valid         : out STD_LOGIC;

            out_matrix          : out std_logic_vector(31 downto 0);
            out_matrix_en       : out std_logic;
            out_matrix_end_row  : out std_logic;
            out_matrix_end      : out std_logic
        );
    end component fox_node;
    
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
    
    
    signal reset    : std_logic;
    
    signal uart_din         : std_logic_vector(7 downto 0);
    signal uart_din_valid   : std_logic;
    
    constant BAUD_RATE  : integer := 115200;
    constant PARITY_BIT : string := "none";
    constant USE_DEBOUNCER  : boolean := True;

    -- Result node parameters
    constant RESULT_X_COORD  : integer := 0;
    constant RESULT_Y_COORD  : integer := 0;
    
    -- Array of message interfaces between nodes
    signal x_messages_out, y_messages_out : t_Message;
    signal x_messages_out_valid, y_messages_out_valid : t_MessageValid;
    signal x_messages_in, y_messages_in : t_Message;
    signal x_messages_in_valid, y_messages_in_valid : t_MessageValid;

    constant FOX_DIVIDE_ENABLED     : std_logic := '0';
    constant RESULT_DIVIDE_ENABLED  : std_logic := '1';
    constant MULTIPLY_ENABLED       : std_logic := '1';
    
    constant FOX_FIRMWARE           : string := "firmware_hoplite.hex";
    constant RESULT_FIRMWARE        : string := "firmware_hoplite_result.hex";

    constant FOX_MEM_SIZE           : integer := 4096;
    constant RESULT_MEM_SIZE        : integer := 8192;

begin

    reset   <= not reset_n;

    -- Generate the network
    NETWORK_ROW_GEN: for i in 0 to (NETWORK_ROWS-1) generate
        NETWORK_COL_GEN: for j in 0 to (NETWORK_COLS-1) generate
            constant prev_y         : integer := ((i-1) mod NETWORK_ROWS);
            constant prev_x         : integer := ((j-1) mod NETWORK_COLS);
            constant curr_y         : integer := i;
            constant curr_x         : integer := j;
            constant next_y         : integer := ((i+1) mod NETWORK_ROWS);
            constant next_x         : integer := ((j+1) mod NETWORK_COLS);
            constant node_number    : integer := i * NETWORK_ROWS + j;
            constant y_offset       : integer := i * (FOX_MATRIX_SIZE);
            constant x_offset       : integer := j * (FOX_MATRIX_SIZE);
        begin
            -- Connect in and out messages
            x_messages_in(curr_x, curr_y)       <= x_messages_out(prev_x, curr_y);
            x_messages_in_valid(curr_x, curr_y) <= x_messages_out_valid(prev_x, curr_y);

            y_messages_in(curr_x, curr_y)       <= y_messages_out(curr_x, next_y);
            y_messages_in_valid(curr_x, curr_y) <= y_messages_out_valid(curr_x, next_y);
        
            -- Instantiate node
            RESULT_GEN: if (curr_x = RESULT_X_COORD and curr_y = RESULT_Y_COORD) generate
                out_char(curr_x, curr_y)    <= uart_din;
                out_char_en(curr_x, curr_y) <= uart_din_valid;
            
                RESULT_NODE_INITIALISE: fox_node
                generic map (
                    -- Entire network parameters
                    NETWORK_ROWS    => NETWORK_ROWS,
                    NETWORK_COLS    => NETWORK_COLS,
                    NETWORK_NODES   => NETWORK_NODES,

                    -- Fox's algorithm network paramters
                    FOX_NETWORK_STAGES  => FOX_NETWORK_STAGES,
                    FOX_NETWORK_NODES   => FOX_NETWORK_NODES,

                    -- Result node parameters
                    RESULT_X_COORD  => RESULT_X_COORD,
                    RESULT_Y_COORD  => RESULT_Y_COORD,
                
                    -- Node parameters
                    X_COORD         => curr_x,
                    Y_COORD         => curr_y,
                    NODE_NUMBER     => node_number,

                    -- Packet parameters
                    COORD_BITS              => COORD_BITS,
                    MULTICAST_GROUP_BITS    => MULTICAST_GROUP_BITS,
                    MATRIX_TYPE_BITS        => MATRIX_TYPE_BITS,
                    MATRIX_COORD_BITS       => MATRIX_COORD_BITS, 
                    MATRIX_ELEMENT_BITS     => MATRIX_ELEMENT_BITS,
                    BUS_WIDTH               => BUS_WIDTH,

                    -- Matrix parameters
                    TOTAL_MATRIX_SIZE       => TOTAL_MATRIX_SIZE,
                    FOX_MATRIX_SIZE         => FOX_MATRIX_SIZE,
                    -- TODO Implement matrix initialisation files for each node
                    MATRIX_FILE     => "none",
                    
                    -- Matrix offset for node
                    MATRIX_X_OFFSET => x_offset,
                    MATRIX_Y_OFFSET => y_offset,

                    -- NIC parameters
                    FIFO_DEPTH      => RESULT_FIFO_DEPTH,
                    
                    -- PicoRV32 core parameters
                    DIVIDE_ENABLED     => RESULT_DIVIDE_ENABLED,
                    MULTIPLY_ENABLED   => MULTIPLY_ENABLED,
                    FIRMWARE           => RESULT_FIRMWARE,
                    MEM_SIZE           => RESULT_MEM_SIZE
                )
                port map (
                    clk                 => clk,
                    reset_n             => reset_n,
                    
                    LED                 => LED(node_number),

                    out_char            => uart_din,
                    out_char_en         => uart_din_valid,
                    
                    -- Messages incoming to router
                    x_in                => x_messages_in(curr_x, curr_y),
                    x_in_valid          => x_messages_in_valid(curr_x, curr_y),                  
                    y_in                => y_messages_in(curr_x, curr_y),
                    y_in_valid          => y_messages_in_valid(curr_x, curr_y),
                    
                    -- Messages outgoing from router
                    x_out               => x_messages_out(curr_x, curr_y),
                    x_out_valid         => x_messages_out_valid(curr_x, curr_y),
                    y_out               => y_messages_out(curr_x, curr_y),
                    y_out_valid         => y_messages_out_valid(curr_x, curr_y),

                    out_matrix          => out_matrix(curr_x, curr_y),
                    out_matrix_en       => out_matrix_en(curr_x, curr_y),
                    out_matrix_end_row  => out_matrix_end_row(curr_x, curr_y),
                    out_matrix_end      => out_matrix_end(curr_x, curr_y)
                );  
                
                UART_GEN: if (ENABLE_UART = True) generate                
                    UART_INITIALISE: UART
                        generic map (
                            CLK_FREQ      => CLK_FREQ,   -- system clock frequency in Hz
                            BAUD_RATE     => BAUD_RATE, -- baud rate value
                            PARITY_BIT    => PARITY_BIT, -- type of parity: "none", "even", "odd", "mark", "space"
                            USE_DEBOUNCER => USE_DEBOUNCER    -- enable/disable debouncer
                        )
                        port map (
                            -- CLOCK AND RESET
                            CLK          => clk, -- system clock
                            RST          => reset, -- high active synchronous reset
                            -- UART INTERFACE
                            UART_TXD     => uart_tx, -- serial transmit data
                            UART_RXD     => '1',     -- serial receive data
                            -- USER DATA INPUT INTERFACE
                            DIN          => uart_din, -- input data to be transmitted over UART
                            DIN_VLD      => uart_din_valid, -- when DIN_VLD = 1, input data (DIN) are valid
                            DIN_RDY      => open, -- when DIN_RDY = 1, transmitter is ready and valid input data will be accepted for transmiting
                            -- USER DATA OUTPUT INTERFACE
                            DOUT         => open, -- output data received via UART
                            DOUT_VLD     => open, -- when DOUT_VLD = 1, output data (DOUT) are valid (is assert only for one clock cycle)
                            FRAME_ERROR  => open, -- when FRAME_ERROR = 1, stop bit was invalid (is assert only for one clock cycle)
                            PARITY_ERROR => open  -- when PARITY_ERROR = 1, parity bit was invalid (is assert only for one clock cycle)
                        );
                end generate UART_GEN;      
            end generate RESULT_GEN;
            
            FOX_GEN: if (curr_x /= RESULT_X_COORD or curr_y /= RESULT_Y_COORD) generate
                FOX_NODE_INITIALISE: fox_node
                generic map (
                    -- Entire network parameters
                    NETWORK_ROWS    => NETWORK_ROWS,
                    NETWORK_COLS    => NETWORK_COLS,
                    NETWORK_NODES   => NETWORK_NODES,

                    -- Fox's algorithm network paramters
                    FOX_NETWORK_STAGES  => FOX_NETWORK_STAGES,
                    FOX_NETWORK_NODES   => FOX_NETWORK_NODES,

                    -- Result node parameters
                    RESULT_X_COORD  => RESULT_X_COORD,
                    RESULT_Y_COORD  => RESULT_Y_COORD,
                
                    -- Node parameters
                    X_COORD         => curr_x,
                    Y_COORD         => curr_y,
                    NODE_NUMBER     => node_number,

                    -- Packet parameters
                    COORD_BITS              => COORD_BITS,
                    MULTICAST_GROUP_BITS    => MULTICAST_GROUP_BITS,
                    MATRIX_TYPE_BITS        => MATRIX_TYPE_BITS,
                    MATRIX_COORD_BITS       => MATRIX_COORD_BITS, 
                    MATRIX_ELEMENT_BITS     => MATRIX_ELEMENT_BITS,
                    BUS_WIDTH               => BUS_WIDTH,

                    -- Matrix parameters
                    TOTAL_MATRIX_SIZE       => TOTAL_MATRIX_SIZE,
                    FOX_MATRIX_SIZE         => FOX_MATRIX_SIZE,
                    -- TODO Implement matrix initialisation files for each node
                    MATRIX_FILE     => "none",
                    
                    -- Matrix offset for node
                    MATRIX_X_OFFSET => x_offset,
                    MATRIX_Y_OFFSET => y_offset,

                    -- NIC parameters
                    FIFO_DEPTH      => FOX_FIFO_DEPTH,
                    
                    -- PicoRV32 core parameters
                    DIVIDE_ENABLED     => FOX_DIVIDE_ENABLED,
                    MULTIPLY_ENABLED   => MULTIPLY_ENABLED,
                    FIRMWARE           => FOX_FIRMWARE,
                    MEM_SIZE           => FOX_MEM_SIZE
                )
                port map (
                    clk                 => clk,
                    reset_n             => reset_n,
                    
                    LED                 => LED(node_number),

                    out_char            => out_char(curr_x, curr_y),
                    out_char_en         => out_char_en(curr_x, curr_y),
                    
                    -- Messages incoming to router
                    x_in                => x_messages_in(curr_x, curr_y),
                    x_in_valid          => x_messages_in_valid(curr_x, curr_y),                  
                    y_in                => y_messages_in(curr_x, curr_y),
                    y_in_valid          => y_messages_in_valid(curr_x, curr_y),
                    
                    -- Messages outgoing from router
                    x_out               => x_messages_out(curr_x, curr_y),
                    x_out_valid         => x_messages_out_valid(curr_x, curr_y),
                    y_out               => y_messages_out(curr_x, curr_y),
                    y_out_valid         => y_messages_out_valid(curr_x, curr_y),

                    out_matrix          => out_matrix(curr_x, curr_y),
                    out_matrix_en       => out_matrix_en(curr_x, curr_y),
                    out_matrix_end_row  => out_matrix_end_row(curr_x, curr_y),
                    out_matrix_end      => out_matrix_end(curr_x, curr_y)
                );
            end generate FOX_GEN;
        end generate NETWORK_COL_GEN;
    end generate NETWORK_ROW_GEN;

    
end Behavioral;
