library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use ieee.std_logic_unsigned.all;

entity UART_tx_buffered is
    Generic (
        CLK_FREQ        : integer := 50e6;
        BAUD_RATE       : integer := 115200;
        PARITY_BIT      : string  := "none";
        USE_DEBOUNCER   : boolean := True;

        BUFFER_DEPTH    : integer := 50
    ); 
    Port (
        clk     : in std_logic;
        reset_n : in std_logic;

        data_in         : in std_logic_vector(7 downto 0);
        data_in_valid   : in std_logic;

        uart_tx         : out std_logic;

        buffer_full     : out std_logic
    );
end UART_tx_buffered;

architecture Behavioral of UART_tx_buffered is

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

    signal reset    : std_logic;

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

    buffer_full     <= uart_tx_buffer_full;

    pe_to_uart          <= data_in;
    pe_to_uart_valid    <= data_in_valid;
        
    UART_BUFFER: fifo_sync
        generic map (
            BUS_WIDTH   => UART_BUS_WIDTH,
            FIFO_DEPTH  => BUFFER_DEPTH
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

    UART_INITIALISE: UART
        generic map (
            CLK_FREQ      => CLK_FREQ,
            BAUD_RATE     => BAUD_RATE,
            PARITY_BIT    => PARITY_BIT,
            USE_DEBOUNCER => USE_DEBOUNCER
        )
        port map (
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

end Behavioral;
