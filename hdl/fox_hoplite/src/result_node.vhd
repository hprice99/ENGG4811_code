----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 08/05/2021 07:24:23 PM
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

library xil_defaultlib;
use xil_defaultlib.math_functions.all;
use xil_defaultlib.fox_defs.all;

entity result_node is
    Generic (
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
        MULTICAST_COORD_BITS    : integer := 1;
        MATRIX_TYPE_BITS        : integer := 1;
        MATRIX_COORD_BITS       : integer := 8;
        MATRIX_ELEMENT_BITS     : integer := 32;
        BUS_WIDTH               : integer := 56;

        -- Matrix parameters
        TOTAL_MATRIX_SIZE       : integer := 32;
        FOX_MATRIX_SIZE         : integer := 16;
        
        USE_INITIALISATION_FILE : boolean := True;
        MATRIX_FILE             : string  := "none";
        MATRIX_FILE_LENGTH      : integer := 0;
        
        -- Matrix offset for node
        MATRIX_X_OFFSET : integer := 0;
        MATRIX_Y_OFFSET : integer := 0;

        -- NIC parameters
        NIC_FIFO_DEPTH     : integer := 32;

        -- UART parameters
        CLK_FREQ           : integer := 50e6;
        ENABLE_UART        : boolean := False;
        UART_FIFO_DEPTH    : integer := 50;
        
        -- PicoRV32 core parameters
        DIVIDE_ENABLED     : std_logic := '0';
        MULTIPLY_ENABLED   : std_logic := '1';
        FIRMWARE           : string    := "firmware.hex";
        MEM_SIZE           : integer   := 4096
    );
    Port (
        clk                 : in std_logic;
        reset_n             : in std_logic;

        LED                 : out std_logic;

        out_char            : out std_logic_vector(7 downto 0);
        out_char_en         : out std_logic;

        uart_tx             : out std_logic;
        
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
end result_node;

architecture Behavioral of result_node is

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
            MULTICAST_COORD_BITS    : integer := 1;
            MATRIX_TYPE_BITS        : integer := 1;
            MATRIX_COORD_BITS       : integer := 8;
            MATRIX_ELEMENT_BITS     : integer := 32;
            BUS_WIDTH               : integer := 56;

            -- Matrix parameters
            TOTAL_MATRIX_SIZE   : integer := 32;
            FOX_MATRIX_SIZE     : integer := 16;
            
            USE_INITIALISATION_FILE : boolean := True;
            MATRIX_FILE             : string  := "none";
            MATRIX_FILE_LENGTH      : integer := 0;
            
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
            out_char_ready      : in std_logic;
            
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
    
    constant BAUD_RATE      : integer := 115200;
    constant PARITY_BIT     : string := "none";
    constant USE_DEBOUNCER  : boolean := True;
    
    constant UART_BUS_WIDTH : integer := 8;
    
    signal pe_to_uart           : std_logic_vector(7 downto 0);
    signal pe_to_uart_valid     : std_logic;
    signal pe_to_uart_ready     : std_logic;
    
    signal uart_tx_ready        : std_logic;
    signal uart_tx_data         : std_logic_vector(7 downto 0);
    signal uart_tx_data_valid   : std_logic;
    
    signal uart_tx_buffer_read_valid    : std_logic;
    signal uart_tx_buffer_full, uart_tx_buffer_empty    : std_logic;

begin

    reset   <= not reset_n;

    -- Instantiate node
    out_char    <= pe_to_uart;
    out_char_en <= pe_to_uart_valid;

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
            X_COORD         => X_COORD,
            Y_COORD         => Y_COORD,
            NODE_NUMBER     => NODE_NUMBER,
    
            -- Packet parameters
            COORD_BITS              => COORD_BITS,
            MULTICAST_GROUP_BITS    => MULTICAST_GROUP_BITS,
            MULTICAST_COORD_BITS    => MULTICAST_COORD_BITS,
            MATRIX_TYPE_BITS        => MATRIX_TYPE_BITS,
            MATRIX_COORD_BITS       => MATRIX_COORD_BITS, 
            MATRIX_ELEMENT_BITS     => MATRIX_ELEMENT_BITS,
            BUS_WIDTH               => BUS_WIDTH,
    
            -- Matrix parameters
            TOTAL_MATRIX_SIZE       => TOTAL_MATRIX_SIZE,
            FOX_MATRIX_SIZE         => FOX_MATRIX_SIZE,
            
            USE_INITIALISATION_FILE => USE_INITIALISATION_FILE,
            MATRIX_FILE             => MATRIX_FILE,
            MATRIX_FILE_LENGTH      => MATRIX_FILE_LENGTH,
            
            -- Matrix offset for node
            MATRIX_X_OFFSET => MATRIX_X_OFFSET,
            MATRIX_Y_OFFSET => MATRIX_X_OFFSET,
    
            -- NIC parameters
            FIFO_DEPTH      => RESULT_FIFO_DEPTH,
            
            -- PicoRV32 core parameters
            DIVIDE_ENABLED     => DIVIDE_ENABLED,
            MULTIPLY_ENABLED   => MULTIPLY_ENABLED,
            FIRMWARE           => FIRMWARE,
            MEM_SIZE           => MEM_SIZE
        )
        port map (
            clk                 => clk,
            reset_n             => reset_n,
            
            LED                 => LED,
    
            out_char            => pe_to_uart,
            out_char_en         => pe_to_uart_valid,
            out_char_ready      => pe_to_uart_ready,
            
            -- Messages incoming to router
            x_in                => x_in,
            x_in_valid          => x_in_valid,
            y_in                => y_in,
            y_in_valid          => y_in_valid,
            
            -- Messages outgoing from router
            x_out               => x_out,
            x_out_valid         => x_out_valid,
            y_out               => y_out,
            y_out_valid         => y_out_valid,
    
            out_matrix          => out_matrix,
            out_matrix_en       => out_matrix_en,
            out_matrix_end_row  => out_matrix_end_row,
            out_matrix_end      => out_matrix_end
        );
        
    pe_to_uart_ready    <= not uart_tx_buffer_full;
        
    UART_BUFFER: fifo_sync
        generic map (
            BUS_WIDTH   => UART_BUS_WIDTH,
            FIFO_DEPTH  => UART_FIFO_DEPTH
        )
        port map (
            clk         => clk,
            reset_n     => reset_n,

            write_en    => pe_to_uart_valid,
            write_data  => pe_to_uart,

            read_en     => uart_tx_buffer_read_valid,
            read_data   => uart_tx_data,

            full        => uart_tx_buffer_full,
            empty       => uart_tx_buffer_empty
        );

    TX_BUFFER_READ_VALID: process (uart_tx_ready, uart_tx_buffer_empty)
    begin
        if (uart_tx_buffer_empty = '0') then
            uart_tx_buffer_read_valid   <= uart_tx_ready;
        else
            uart_tx_buffer_read_valid   <= '0';
        end if;
    end process TX_BUFFER_READ_VALID;

    UART_GEN: if (ENABLE_UART = True) generate
        UART_INITIALISE: UART
            generic map (
                CLK_FREQ      => CLK_FREQ,
                BAUD_RATE     => BAUD_RATE,
                PARITY_BIT    => PARITY_BIT,
                USE_DEBOUNCER => USE_DEBOUNCER
            )
            port map (
                -- CLOCK AND RESET
                CLK          => clk,
                RST          => reset,

                UART_TXD     => uart_tx,
                UART_RXD     => '1',
                
                DIN          => uart_tx_data, 
                DIN_VLD      => uart_tx_buffer_read_valid, 
                DIN_RDY      => uart_tx_ready,

                DOUT         => open,
                DOUT_VLD     => open, 
                FRAME_ERROR  => open, 
                PARITY_ERROR => open
            );
    end generate UART_GEN;

end Behavioral;
