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
-- use IEEE.NUMERIC_STD.ALL;
-- use ieee.std_logic_unsigned.all;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity top is
    Port ( 
           CPU_RESETN   : in STD_LOGIC;
           CLK_100MHZ   : in STD_LOGIC;
           SW           : in STD_LOGIC_VECTOR(3 downto 0);
           LED          : out STD_LOGIC_VECTOR(15 downto 0);
           LED16_B      : out STD_LOGIC;
           LED16_G      : out STD_LOGIC;
           LED17_R      : out STD_LOGIC;
           LED17_B      : out STD_LOGIC
    );
end top;

architecture Behavioral of top is

    component system
        generic (
             USE_ILA            : std_logic := '1';
             DIVIDE_ENABLED     : std_logic := '0';
             MULTIPLY_ENABLED   : std_logic := '1';
             FIRMWARE           : string    := "firmware.hex";
             MEM_SIZE           : integer   := 4096
        );
        port (
            clk                     : in std_logic;
            resetn                  : in std_logic;
            sw                      : in std_logic;
            in_byte_en              : in std_logic;
            in_byte                 : in std_logic_vector(7 downto 0);
            led                     : out std_logic_vector(15 downto 0);
            RGB_LED                 : out std_logic;
            out_byte_en             : out std_logic;
            out_byte                : out std_logic_vector(7 downto 0);
            out_matrix_en           : out std_logic;
            out_matrix              : out std_logic_vector(7 downto 0);
            out_matrix_end_row      : out std_logic;
            out_matrix_end          : out std_logic;
            out_matrix_position_en  : out std_logic;
            out_matrix_position     : out std_logic_vector(7 downto 0);
            trap                    : out std_logic
        );
    end component system;
    
    constant ila_parameter      : std_logic := '0';
    constant divide_parameter   : std_logic := '0';
    constant multiply_parameter : std_logic := '1';
    
    component hoplite_router
        generic (
            BUS_WIDTH   : integer := 32;
            X_COORD     : integer := 0;
            Y_COORD     : integer := 0;
            COORD_BITS  : integer := 1
        );
        port (
            clk             : in STD_LOGIC;
            reset_n         : in STD_LOGIC;
            x_in            : in STD_LOGIC_VECTOR((BUS_WIDTH-1) downto 0);
            x_in_valid      : in STD_LOGIC;
            y_in            : in STD_LOGIC_VECTOR((BUS_WIDTH-1) downto 0);
            y_in_valid      : in STD_LOGIC;
            pe_in           : in STD_LOGIC_VECTOR((BUS_WIDTH-1) downto 0);
            pe_in_valid     : in STD_LOGIC;
            x_out           : out STD_LOGIC_VECTOR((BUS_WIDTH-1) downto 0);
            x_out_valid     : out STD_LOGIC;
            y_out           : out STD_LOGIC_VECTOR((BUS_WIDTH-1) downto 0);
            y_out_valid     : out STD_LOGIC;
            pe_out          : out STD_LOGIC_VECTOR((BUS_WIDTH-1) downto 0);
            pe_out_valid    : out STD_LOGIC;
            pe_backpressure : out STD_LOGIC
        );
    end component hoplite_router;
    
    constant NETWORK_ROWS   : integer := 2;
    constant NETWORK_COLS   : integer := 2;
    constant NETWORK_NODES  : integer := NETWORK_ROWS * NETWORK_COLS;
    constant COORD_BITS     : integer := 1;
    constant BUS_WIDTH      : integer := 8 + 2 * COORD_BITS;
    
    -- Array of message interfaces between nodes
    type t_Bytes is array (0 to (NETWORK_ROWS-1), 0 to (NETWORK_COLS-1)) of std_logic_vector(7 downto 0);
    type t_Message is array (0 to (NETWORK_ROWS-1), 0 to (NETWORK_COLS-1)) of std_logic_vector((BUS_WIDTH-1) downto 0);
    type t_MessageValid is array (0 to (NETWORK_ROWS-1), 0 to (NETWORK_COLS-1)) of std_logic;

    signal pe_in_bytes, pe_out_bytes : t_Bytes;
    signal x_messages, y_messages, pe_in_messages, pe_out_messages : t_Message;
    signal x_messages_valid, y_messages_valid, pe_in_messages_valid, pe_out_messages_valid : t_MessageValid;
    
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
    
    signal sw0_pipelined, sw1_pipelined, sw2_pipelined, sw3_pipelined : std_logic;
    constant SWITCH_PIPELINE_STAGES : integer := 30;
    constant MEM_SIZE : integer := 1024;

begin

    SW0_PIPELINE : pipeline
        generic map (
            STAGES  => SWITCH_PIPELINE_STAGES
        )
        port map (
            clk         => CLK_100MHZ,
            d_in        => SW(0),
            d_out       => sw0_pipelined
        );

    CORE_0 : system
        generic map(
           USE_ILA          => ila_parameter, 
           DIVIDE_ENABLED   => divide_parameter,
           MULTIPLY_ENABLED => multiply_parameter,
           FIRMWARE         => "firmware_hoplite.hex",
           MEM_SIZE         => MEM_SIZE
        )
        port map (
            clk                         => CLK_100MHZ,
            resetn                      => CPU_RESETN,
            sw                          => sw0_pipelined,
            in_byte_en                  => pe_out_messages_valid(0, 0),
            in_byte                     => pe_out_bytes(0, 0),
            led                         => led,
            RGB_LED                     => LED16_B,
            out_byte_en                 => pe_in_messages_valid(0, 0),
            out_byte                    => pe_in_bytes(0, 0),
            out_matrix_en               => open,
            out_matrix                  => open,
            out_matrix_end_row          => open,
            out_matrix_end              => open,
            out_matrix_position_en      => open,
            out_matrix_position         => open,
            trap                        => open
        );
    
    pe_in_messages(0, 0) <= pe_in_bytes(0, 0) & "0" & "0";
    pe_out_bytes(0, 0) <= pe_out_messages(0, 0)(7 downto 0);
        
    ROUTER_0: hoplite_router
    generic map (
        BUS_WIDTH   => BUS_WIDTH,
        X_COORD     => 0,
        Y_COORD     => 0,
        COORD_BITS  => COORD_BITS
    )
    port map (
        clk                 => CLK_100MHZ,
        reset_n             => CPU_RESETN,
        x_in                => x_messages(1, 0),
        x_in_valid          => x_messages_valid(1, 0),
        y_in                => y_messages(0, 1),
        y_in_valid          => y_messages_valid(0, 1),
        pe_in               => pe_in_messages(0, 0),
        pe_in_valid         => pe_in_messages_valid(0, 0),
        x_out               => x_messages(0, 0),
        x_out_valid         => x_messages_valid(0, 0),
        y_out               => y_messages(0, 0),
        y_out_valid         => y_messages_valid(0, 0),
        pe_out              => pe_out_messages(0, 0),
        pe_out_valid        => pe_out_messages_valid(0, 0),
        pe_backpressure     => open
    );
        
    SW1_PIPELINE : pipeline
        generic map (
            STAGES  => switch_pipeline_stages
        )
        port map (
            clk         => CLK_100MHZ,
            d_in        => SW(1),
            d_out       => sw1_pipelined
        );
        
    CORE_1 : system
        generic map(
           USE_ILA          => ila_parameter, 
           DIVIDE_ENABLED   => divide_parameter,
           MULTIPLY_ENABLED => multiply_parameter,
           FIRMWARE         => "firmware.hex",
           MEM_SIZE         => mem_size
        )
        port map (
            clk                         => CLK_100MHZ,
            resetn                      => CPU_RESETN,
            sw                          => sw1_pipelined,
            in_byte_en                  => pe_out_messages_valid(1, 0),
            in_byte                     => pe_out_bytes(1, 0),
            led                         => open,
            RGB_LED                     => LED16_G,
            out_byte_en                 => pe_in_messages_valid(1, 0),
            out_byte                    => pe_in_bytes(1, 0),
            out_matrix_en               => open,
            out_matrix                  => open,
            out_matrix_end_row          => open,
            out_matrix_end              => open,
            out_matrix_position_en      => open,
            out_matrix_position         => open,
            trap                        => open
        );
        
    pe_in_messages(1, 0) <= pe_in_bytes(1, 0) & "0" & "1";
    pe_out_bytes(1, 0) <= pe_out_messages(1, 0)(7 downto 0);
        
    ROUTER_1: hoplite_router
    generic map (
        BUS_WIDTH   => BUS_WIDTH,
        X_COORD     => 1,
        Y_COORD     => 0,
        COORD_BITS  => COORD_BITS
    )
    port map (
        clk                 => CLK_100MHZ,
        reset_n             => CPU_RESETN,
        x_in                => x_messages(0, 0),
        x_in_valid          => x_messages_valid(0, 0),
        y_in                => y_messages(1, 1),
        y_in_valid          => y_messages_valid(1, 1),
        pe_in               => pe_in_messages(1, 0),
        pe_in_valid         => pe_in_messages_valid(1, 0),
        x_out               => x_messages(1, 0),
        x_out_valid         => x_messages_valid(1, 0),
        y_out               => y_messages(1, 0),
        y_out_valid         => y_messages_valid(1, 0),
        pe_out              => pe_out_messages(1, 0),
        pe_out_valid        => pe_out_messages_valid(1, 0),
        pe_backpressure     => open
    );
        
    SW2_PIPELINE : pipeline
        generic map (
            STAGES  => switch_pipeline_stages
        )
        port map (
            clk         => CLK_100MHZ,
            d_in        => SW(2),
            d_out       => sw2_pipelined
        );
        
    CORE_2 : system
        generic map(
           USE_ILA          => ila_parameter, 
           DIVIDE_ENABLED   => divide_parameter,
           MULTIPLY_ENABLED => multiply_parameter,
           FIRMWARE         => "firmware.hex",
           MEM_SIZE         => mem_size
        )
        port map (
            clk                         => CLK_100MHZ,
            resetn                      => CPU_RESETN,
            sw                          => sw2_pipelined,
            in_byte_en                  => pe_out_messages_valid(0, 1),
            in_byte                     => pe_out_bytes(0, 1),
            led                         => open,
            RGB_LED                     => LED17_R,
            out_byte_en                 => pe_in_messages_valid(0, 1),
            out_byte                    => pe_in_bytes(0, 1),
            out_matrix_en               => open,
            out_matrix                  => open,
            out_matrix_end_row          => open,
            out_matrix_end              => open,
            out_matrix_position_en      => open,
            out_matrix_position         => open,
            trap                        => open
        );
        
    pe_in_messages(0, 1) <= pe_in_bytes(0, 1) & "1" & "0";
    pe_out_bytes(0, 1) <= pe_out_messages(0, 1)(7 downto 0);
        
    ROUTER_2: hoplite_router
    generic map (
        BUS_WIDTH   => BUS_WIDTH,
        X_COORD     => 0,
        Y_COORD     => 1,
        COORD_BITS  => COORD_BITS
    )
    port map (
        clk                 => CLK_100MHZ,
        reset_n             => CPU_RESETN,
        x_in                => x_messages(1, 1),
        x_in_valid          => x_messages_valid(1, 1),
        y_in                => y_messages(0, 0),
        y_in_valid          => y_messages_valid(0, 0),
        pe_in               => pe_in_messages(0, 1),
        pe_in_valid         => pe_in_messages_valid(0, 1),
        x_out               => x_messages(0, 1),
        x_out_valid         => x_messages_valid(0, 1),
        y_out               => y_messages(0, 1),
        y_out_valid         => y_messages_valid(0, 1),
        pe_out              => pe_out_messages(0, 1),
        pe_out_valid        => pe_out_messages_valid(0, 1),
        pe_backpressure     => open
    );
        
    SW3_PIPELINE : pipeline
        generic map (
            STAGES  => switch_pipeline_stages
        )
        port map (
            clk         => CLK_100MHZ,
            d_in        => SW(3),
            d_out       => sw3_pipelined
        );
        
    CORE_3 : system
        generic map(
           USE_ILA          => ila_parameter, 
           DIVIDE_ENABLED   => divide_parameter,
           MULTIPLY_ENABLED => multiply_parameter,
           FIRMWARE         => "firmware.hex",
           MEM_SIZE         => mem_size
        )
        port map (
            clk                         => CLK_100MHZ,
            resetn                      => CPU_RESETN,
            sw                          => sw3_pipelined,
            in_byte_en                  => pe_out_messages_valid(1, 1),
            in_byte                     => pe_out_bytes(1, 1),
            led                         => open,
            RGB_LED                     => LED17_B,
            out_byte_en                 => pe_in_messages_valid(1, 1),
            out_byte                    => pe_in_bytes(1, 1),
            out_matrix_en               => open,
            out_matrix                  => open,
            out_matrix_end_row          => open,
            out_matrix_end              => open,
            out_matrix_position_en      => open,
            out_matrix_position         => open,
            trap                        => open
        );

    pe_in_messages(1, 1) <= pe_in_bytes(1, 1) & "0" & "0";
    pe_out_bytes(1, 1) <= pe_out_messages(1, 1)(7 downto 0);
        
    ROUTER_3: hoplite_router
    generic map (
        BUS_WIDTH   => BUS_WIDTH,
        X_COORD     => 1,
        Y_COORD     => 1,
        COORD_BITS  => COORD_BITS
    )
    port map (
        clk                 => CLK_100MHZ,
        reset_n             => CPU_RESETN,
        x_in                => x_messages(0, 1),
        x_in_valid          => x_messages_valid(0, 1),
        y_in                => y_messages(1, 0),
        y_in_valid          => y_messages_valid(1, 0),
        pe_in               => pe_in_messages(1, 1),
        pe_in_valid         => pe_in_messages_valid(1, 1),
        x_out               => x_messages(1, 1),
        x_out_valid         => x_messages_valid(1, 1),
        y_out               => y_messages(1, 1),
        y_out_valid         => y_messages_valid(1, 1),
        pe_out              => pe_out_messages(1, 1),
        pe_out_valid        => pe_out_messages_valid(1, 1),
        pe_backpressure     => open
    );

end Behavioral;
