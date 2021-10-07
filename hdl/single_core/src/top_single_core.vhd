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
use xil_defaultlib.packet_defs.all;
use xil_defaultlib.fox_defs.all;
use xil_defaultlib.matrix_config.all;
use xil_defaultlib.firmware_config.all;
use xil_defaultlib.math_functions.all;

entity top_single_core is
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
end top_single_core;

architecture Behavioral of top_single_core is

    component system_single_core
        generic (
             DIVIDE_ENABLED     : std_logic := '0';
             MULTIPLY_ENABLED   : std_logic := '1';
             
             USE_MATRIX_INIT_FILE : boolean := True;
             
             FIRMWARE           : string    := "firmware.hex";
             MEM_SIZE           : integer   := 4096
        );
        port (
            clk                     : in std_logic;
            reset_n                 : in std_logic;

            out_char                : out std_logic_vector(7 downto 0);
            out_char_en             : out std_logic;
            out_char_ready          : in std_logic;
            
            matrix_type_in          : in std_logic_vector((MATRIX_TYPE_BITS-1) downto 0);
            matrix_x_coord_in       : in std_logic_vector((MATRIX_COORD_BITS-1) downto 0);
            matrix_y_coord_in       : in std_logic_vector((MATRIX_COORD_BITS-1) downto 0);
            matrix_element_in       : in std_logic_vector((MATRIX_ELEMENT_BITS-1) downto 0);
            message_in_valid        : in std_logic;
            message_in_available    : in std_logic;
            message_in_read         : out std_logic;
            
            out_matrix              : out std_logic_vector(31 downto 0);
            out_matrix_en           : out std_logic;
            out_matrix_end_row      : out std_logic;
            out_matrix_end          : out std_logic;
            
            matrix_multiply_done    : out std_logic
        );
    end component system_single_core;
    
    constant divide_parameter   : std_logic := '1';
    constant multiply_parameter : std_logic := '1';
    
    component pipeline
        generic (
            STAGES  : integer := 10
        );
        port (
            clk     : in STD_LOGIC;
            d_in    : in STD_LOGIC;
            d_out   : out STD_LOGIC
        );
    end component pipeline;
    
    component UART_tx_buffered is
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
    end component UART_tx_buffered;
    
    signal out_char_buf     : std_logic_vector(7 downto 0);
    signal out_char_en_buf  : std_logic;
    
    signal uart_tx_ready    : std_logic;
    signal uart_buffer_full : std_logic;
    
    constant BAUD_RATE      : integer := 115200;
    constant PARITY_BIT     : string := "none";
    constant USE_DEBOUNCER  : boolean := True;
    
    component rom is
        generic (
            BUS_WIDTH       : integer := 32;
            ROM_DEPTH       : integer := 64;
            ADDRESS_WIDTH   : integer := 6;
            
            INITIALISATION_FILE : string    := "none"
        );
        port (
            clk         : in std_logic;
    
            read_en     : in std_logic;
            read_addr   : in std_logic_vector((ADDRESS_WIDTH-1) downto 0);
            read_data   : out std_logic_vector((BUS_WIDTH-1) downto 0)
        );
    end component rom;
    
    constant COMBINED_MATRIX_FILE   : string := "combined.mif";
    constant MATRIX_FILE_LENGTH     : integer := 2 * TOTAL_MATRIX_ELEMENTS;
    constant ROM_ADDRESS_WIDTH      : integer := ceil_log2(matrix_file_length);
    
    signal rom_read_en      : std_logic;
    signal rom_read_addr    : integer range 0 to MATRIX_FILE_LENGTH;
    signal rom_addr_vect    : std_logic_vector((ROM_ADDRESS_WIDTH-1) downto 0);
    signal rom_read_data    : std_logic_vector((BUS_WIDTH-1) downto 0);
    signal rom_read_valid   : std_logic;
    
    component message_decoder is
        Generic (
            COORD_BITS              : integer := 2;
            MULTICAST_GROUP_BITS    : integer := 1;
            MULTICAST_COORD_BITS    : integer := 1;
            MATRIX_TYPE_BITS        : integer := 1;
            MATRIX_COORD_BITS       : integer := 8;
            MATRIX_ELEMENT_BITS     : integer := 32;
            BUS_WIDTH               : integer := 56
        );
        Port (
            clk                 : in std_logic;
            reset_n             : in std_logic;
            
            packet_in           : in std_logic_vector((BUS_WIDTH-1) downto 0);
            packet_in_valid     : in std_logic;
            
            matrix_type_out     : out std_logic_vector((MATRIX_TYPE_BITS-1) downto 0);
            matrix_x_coord_out  : out std_logic_vector((MATRIX_COORD_BITS-1) downto 0);
            matrix_y_coord_out  : out std_logic_vector((MATRIX_COORD_BITS-1) downto 0);
            matrix_element_out  : out std_logic_vector((MATRIX_ELEMENT_BITS-1) downto 0);
    
            packet_out_valid    : out std_logic;
            packet_read         : in std_logic
        );
    end component message_decoder;
    
    signal matrix_type_in          : std_logic_vector((MATRIX_TYPE_BITS-1) downto 0);
    signal matrix_x_coord_in       : std_logic_vector((MATRIX_COORD_BITS-1) downto 0);
    signal matrix_y_coord_in       : std_logic_vector((MATRIX_COORD_BITS-1) downto 0);
    signal matrix_element_in       : std_logic_vector((MATRIX_ELEMENT_BITS-1) downto 0);
    signal message_in_valid        : std_logic;
    signal message_in_available    : std_logic;
    signal message_in_read         : std_logic;

begin

    CORE: system_single_core
        generic map (
           DIVIDE_ENABLED   => divide_parameter,
           MULTIPLY_ENABLED => multiply_parameter,
           
           USE_MATRIX_INIT_FILE => USE_MATRIX_INIT_FILE, 
            
           FIRMWARE         => FOX_FIRMWARE,
           MEM_SIZE         => FOX_MEM_SIZE
        )
        port map (
            clk                         => clk,
            reset_n                     => reset_n,
            
            out_char                    => out_char_buf,
            out_char_en                 => out_char_en_buf,
            out_char_ready              => uart_tx_ready,
            
            matrix_type_in          => matrix_type_in,
            matrix_x_coord_in       => matrix_x_coord_in,
            matrix_y_coord_in       => matrix_y_coord_in,
            matrix_element_in       => matrix_element_in,
            
            message_in_valid        => message_in_valid,
            message_in_available    => message_in_available,
            message_in_read         => message_in_read,
            
            out_matrix_en               => open,
            out_matrix                  => open,
            out_matrix_end_row          => open,
            out_matrix_end              => open,
            
            matrix_multiply_done        => matrix_multiply_done
        );
        
    out_char    <= out_char_buf;
    out_char_en <= out_char_en_buf;
        
    UART_GEN: if (ENABLE_UART = True) generate
        UART_TX_NODE: uart_tx_buffered
            generic map (
                CLK_FREQ        => CLK_FREQ,
                BAUD_RATE       => BAUD_RATE,
                PARITY_BIT      => PARITY_BIT,
                USE_DEBOUNCER   => USE_DEBOUNCER,
        
                BUFFER_DEPTH    => RESULT_UART_FIFO_DEPTH
            )
            port map (
                clk             => clk,
                reset_n         => reset_n,
        
                data_in         => out_char_buf,
                data_in_valid   => out_char_en_buf,
        
                uart_tx         => uart_tx,
        
                buffer_full     => uart_buffer_full
            );
            
        uart_tx_ready <= not uart_buffer_full;
    end generate UART_GEN;

    NOT_UART_GEN: if (ENABLE_UART = False) generate
        uart_tx_ready   <= '1';
    end generate NOT_UART_GEN;

    ROM_GEN: if (USE_MATRIX_INIT_FILE = True) generate
        MATRIX_ROM: rom
            generic map (
                BUS_WIDTH       => BUS_WIDTH,
                ROM_DEPTH       => MATRIX_FILE_LENGTH,
                ADDRESS_WIDTH   => ROM_ADDRESS_WIDTH,
                
                INITIALISATION_FILE => COMBINED_MATRIX_FILE
            )
            port map (
                clk         => clk,
        
                read_en     => rom_read_en,
                read_addr   => rom_addr_vect,
                read_data   => rom_read_data
            );
            
        rom_read_en     <= '1';
        rom_addr_vect   <= std_logic_vector(to_unsigned(rom_read_addr, ROM_ADDRESS_WIDTH));
        
        -- Loop through the addresses of ROM
        ROM_ADDRESS_COUNTER: process (clk)
        begin
            if (rising_edge(clk)) then
                if (reset_n = '0') then
                    rom_read_addr   <= 0;
                else
                    if (message_in_read = '1' and rom_read_addr < MATRIX_FILE_LENGTH) then
                        rom_read_addr   <= rom_read_addr + 1;
                    end if;
                end if;
            end if;
        end process ROM_ADDRESS_COUNTER;
    
        DECODER: message_decoder
            generic map (
                COORD_BITS              => COORD_BITS,
                MULTICAST_GROUP_BITS    => MULTICAST_GROUP_BITS,
                MULTICAST_COORD_BITS    => MULTICAST_COORD_BITS,
                MATRIX_TYPE_BITS        => MATRIX_TYPE_BITS,
                MATRIX_COORD_BITS       => MATRIX_COORD_BITS,
                MATRIX_ELEMENT_BITS     => MATRIX_ELEMENT_BITS,
                BUS_WIDTH               => BUS_WIDTH
            )
            port map (
                clk                 => clk,
                reset_n             => reset_n,
                
                packet_in           => rom_read_data,
                packet_in_valid     => rom_read_valid,
                
                matrix_type_out     => matrix_type_in,
                matrix_x_coord_out  => matrix_x_coord_in,
                matrix_y_coord_out  => matrix_y_coord_in,
                matrix_element_out  => matrix_element_in,
        
                packet_out_valid    => open,
                packet_read         => message_in_read
            );
    end generate ROM_GEN;
    
    NO_ROM_GEN: if (USE_MATRIX_INIT_FILE = False) generate
        matrix_type_in      <= (others => '0');
        matrix_x_coord_in   <= (others => '0');
        matrix_y_coord_in   <= (others => '0');
        matrix_element_in   <= (others => '0');
    end generate NO_ROM_GEN;

end Behavioral;
