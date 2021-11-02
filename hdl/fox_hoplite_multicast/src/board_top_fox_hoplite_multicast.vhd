library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use ieee.std_logic_unsigned.all;
use IEEE.math_real.all;

library xil_defaultlib;
use xil_defaultlib.math_functions.all;
use xil_defaultlib.firmware_config.all;
use xil_defaultlib.packet_defs.all;
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

    component multicast_ila
        Port (
            clk : in std_logic;
           
            probe0  : in std_logic_vector(1 downto 0);
            probe1  : in std_logic_vector(1 downto 0);
            probe2  : in std_logic_vector(1 downto 0);
            probe3  : in std_logic_vector(1 downto 0);
            probe4  : in std_logic_vector(0 downto 0);
            probe5  : in std_logic_vector(0 downto 0);
            probe6  : in std_logic_vector(0 downto 0);
            probe7  : in std_logic_vector(7 downto 0);
            probe8  : in std_logic_vector(7 downto 0);
            probe9  : in std_logic_vector(31 downto 0);
            probe10 : in std_logic_vector(0 downto 0)
        );
    end component multicast_ila;

    constant ENABLE_MULTICAST_ROUTER_0_ILA : boolean := True;
    
    signal ila_multicast_in_1                : std_logic_vector((BUS_WIDTH-1) downto 0);
    
    signal ila_multicast_in_1_dest               : t_Coordinate;
    signal ila_multicast_in_1_multicast_coord    : t_MulticastCoordinate;
    signal ila_multicast_in_1_matrix_coord       : t_MatrixCoordinate;
    
    signal ila_multicast_in_1_x_dest         : std_logic_vector((COORD_BITS-1) downto 0);
    signal ila_multicast_in_1_y_dest         : std_logic_vector((COORD_BITS-1) downto 0);
    signal ila_multicast_in_1_multicast_x    : std_logic_vector((MULTICAST_COORD_BITS-1) downto 0);
    signal ila_multicast_in_1_multicast_y    : std_logic_vector((MULTICAST_COORD_BITS-1) downto 0);
    signal ila_multicast_in_1_ready          : std_logic_vector((READY_FLAG_BITS-1) downto 0);
    signal ila_multicast_in_1_result         : std_logic_vector((RESULT_FLAG_BITS-1) downto 0);
    signal ila_multicast_in_1_matrix_type    : std_logic_vector((MATRIX_TYPE_BITS-1) downto 0);
    signal ila_multicast_in_1_matrix_x       : std_logic_vector((MATRIX_COORD_BITS-1) downto 0);
    signal ila_multicast_in_1_matrix_y       : std_logic_vector((MATRIX_COORD_BITS-1) downto 0);
    signal ila_multicast_in_1_matrix_element : std_logic_vector((MATRIX_ELEMENT_BITS-1) downto 0);
    signal ila_multicast_in_1_valid          : std_logic;
    
    signal ila_multicast_out_2                : std_logic_vector((BUS_WIDTH-1) downto 0);
    
    signal ila_multicast_out_2_dest               : t_Coordinate;
    signal ila_multicast_out_2_multicast_coord    : t_MulticastCoordinate;
    signal ila_multicast_out_2_matrix_coord       : t_MatrixCoordinate;
    
    signal ila_multicast_out_2_x_dest         : std_logic_vector((COORD_BITS-1) downto 0);
    signal ila_multicast_out_2_y_dest         : std_logic_vector((COORD_BITS-1) downto 0);
    signal ila_multicast_out_2_multicast_x    : std_logic_vector((MULTICAST_COORD_BITS-1) downto 0);
    signal ila_multicast_out_2_multicast_y    : std_logic_vector((MULTICAST_COORD_BITS-1) downto 0);
    signal ila_multicast_out_2_ready          : std_logic_vector((READY_FLAG_BITS-1) downto 0);
    signal ila_multicast_out_2_result         : std_logic_vector((RESULT_FLAG_BITS-1) downto 0);
    signal ila_multicast_out_2_matrix_type    : std_logic_vector((MATRIX_TYPE_BITS-1) downto 0);
    signal ila_multicast_out_2_matrix_x       : std_logic_vector((MATRIX_COORD_BITS-1) downto 0);
    signal ila_multicast_out_2_matrix_y       : std_logic_vector((MATRIX_COORD_BITS-1) downto 0);
    signal ila_multicast_out_2_matrix_element : std_logic_vector((MATRIX_ELEMENT_BITS-1) downto 0);
    signal ila_multicast_out_2_valid          : std_logic;
    
    component hoplite_router_ila
        Port (
            clk : in std_logic;
           
            probe0  : in std_logic_vector(1 downto 0);
            probe1  : in std_logic_vector(1 downto 0);
            probe2  : in std_logic_vector(1 downto 0);
            probe3  : in std_logic_vector(1 downto 0);
            probe4  : in std_logic_vector(0 downto 0);
            probe5  : in std_logic_vector(0 downto 0);
            probe6  : in std_logic_vector(0 downto 0);
            probe7  : in std_logic_vector(7 downto 0);
            probe8  : in std_logic_vector(7 downto 0);
            probe9  : in std_logic_vector(31 downto 0);
            probe10 : in std_logic_vector(0 downto 0)
        );
    end component hoplite_router_ila;
    
    constant ENABLE_HOPLITE_ROUTER_0_ILA : boolean := True;
    
    signal ila_x_in_1        : std_logic_vector((BUS_WIDTH-1) downto 0);
    
    signal ila_x_in_1_dest               : t_Coordinate;
    signal ila_x_in_1_multicast_coord    : t_MulticastCoordinate;
    signal ila_x_in_1_matrix_coord       : t_MatrixCoordinate;
    
    signal ila_x_in_1_x_dest         : std_logic_vector((COORD_BITS-1) downto 0);
    signal ila_x_in_1_y_dest         : std_logic_vector((COORD_BITS-1) downto 0);
    signal ila_x_in_1_multicast_x    : std_logic_vector((MULTICAST_COORD_BITS-1) downto 0);
    signal ila_x_in_1_multicast_y    : std_logic_vector((MULTICAST_COORD_BITS-1) downto 0);
    signal ila_x_in_1_ready          : std_logic_vector((READY_FLAG_BITS-1) downto 0);
    signal ila_x_in_1_result         : std_logic_vector((RESULT_FLAG_BITS-1) downto 0);
    signal ila_x_in_1_matrix_type    : std_logic_vector((MATRIX_TYPE_BITS-1) downto 0);
    signal ila_x_in_1_matrix_x       : std_logic_vector((MATRIX_COORD_BITS-1) downto 0);
    signal ila_x_in_1_matrix_y       : std_logic_vector((MATRIX_COORD_BITS-1) downto 0);
    signal ila_x_in_1_matrix_element : std_logic_vector((MATRIX_ELEMENT_BITS-1) downto 0);
    signal ila_x_in_1_valid          : std_logic;
    
    signal ila_y_in_1        : std_logic_vector((BUS_WIDTH-1) downto 0);
    
    signal ila_y_in_1_dest               : t_Coordinate;
    signal ila_y_in_1_multicast_coord    : t_MulticastCoordinate;
    signal ila_y_in_1_matrix_coord       : t_MatrixCoordinate;

    signal ila_y_in_1_x_dest         : std_logic_vector((COORD_BITS-1) downto 0);
    signal ila_y_in_1_y_dest         : std_logic_vector((COORD_BITS-1) downto 0);
    signal ila_y_in_1_multicast_x    : std_logic_vector((MULTICAST_COORD_BITS-1) downto 0);
    signal ila_y_in_1_multicast_y    : std_logic_vector((MULTICAST_COORD_BITS-1) downto 0);
    signal ila_y_in_1_ready          : std_logic_vector((READY_FLAG_BITS-1) downto 0);
    signal ila_y_in_1_result         : std_logic_vector((RESULT_FLAG_BITS-1) downto 0);
    signal ila_y_in_1_matrix_type    : std_logic_vector((MATRIX_TYPE_BITS-1) downto 0);
    signal ila_y_in_1_matrix_x       : std_logic_vector((MATRIX_COORD_BITS-1) downto 0);
    signal ila_y_in_1_matrix_y       : std_logic_vector((MATRIX_COORD_BITS-1) downto 0);
    signal ila_y_in_1_matrix_element : std_logic_vector((MATRIX_ELEMENT_BITS-1) downto 0);
    signal ila_y_in_1_valid          : std_logic;
    
    signal ila_x_out_2        : std_logic_vector((BUS_WIDTH-1) downto 0);
    
    signal ila_x_out_2_dest               : t_Coordinate;
    signal ila_x_out_2_multicast_coord    : t_MulticastCoordinate;
    signal ila_x_out_2_matrix_coord       : t_MatrixCoordinate;
    
    signal ila_x_out_2_x_dest         : std_logic_vector((COORD_BITS-1) downto 0);
    signal ila_x_out_2_y_dest         : std_logic_vector((COORD_BITS-1) downto 0);
    signal ila_x_out_2_multicast_x    : std_logic_vector((MULTICAST_COORD_BITS-1) downto 0);
    signal ila_x_out_2_multicast_y    : std_logic_vector((MULTICAST_COORD_BITS-1) downto 0);
    signal ila_x_out_2_ready          : std_logic_vector((READY_FLAG_BITS-1) downto 0);
    signal ila_x_out_2_result         : std_logic_vector((RESULT_FLAG_BITS-1) downto 0);
    signal ila_x_out_2_matrix_type    : std_logic_vector((MATRIX_TYPE_BITS-1) downto 0);
    signal ila_x_out_2_matrix_x       : std_logic_vector((MATRIX_COORD_BITS-1) downto 0);
    signal ila_x_out_2_matrix_y       : std_logic_vector((MATRIX_COORD_BITS-1) downto 0);
    signal ila_x_out_2_matrix_element : std_logic_vector((MATRIX_ELEMENT_BITS-1) downto 0);
    signal ila_x_out_2_valid          : std_logic;
    
    signal ila_y_out_2        : std_logic_vector((BUS_WIDTH-1) downto 0);
    
    signal ila_y_out_2_dest               : t_Coordinate;
    signal ila_y_out_2_multicast_coord    : t_MulticastCoordinate;
    signal ila_y_out_2_matrix_coord       : t_MatrixCoordinate;

    signal ila_y_out_2_x_dest         : std_logic_vector((COORD_BITS-1) downto 0);
    signal ila_y_out_2_y_dest         : std_logic_vector((COORD_BITS-1) downto 0);
    signal ila_y_out_2_multicast_x    : std_logic_vector((MULTICAST_COORD_BITS-1) downto 0);
    signal ila_y_out_2_multicast_y    : std_logic_vector((MULTICAST_COORD_BITS-1) downto 0);
    signal ila_y_out_2_ready          : std_logic_vector((READY_FLAG_BITS-1) downto 0);
    signal ila_y_out_2_result         : std_logic_vector((RESULT_FLAG_BITS-1) downto 0);
    signal ila_y_out_2_matrix_type    : std_logic_vector((MATRIX_TYPE_BITS-1) downto 0);
    signal ila_y_out_2_matrix_x       : std_logic_vector((MATRIX_COORD_BITS-1) downto 0);
    signal ila_y_out_2_matrix_y       : std_logic_vector((MATRIX_COORD_BITS-1) downto 0);
    signal ila_y_out_2_matrix_element : std_logic_vector((MATRIX_ELEMENT_BITS-1) downto 0);
    signal ila_y_out_2_valid          : std_logic;

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
            out_matrix_end_row  => open,
            out_matrix_end      => open,
            
            ila_multicast_in_1                => ila_multicast_in_1,
            ila_multicast_in_1_valid          => ila_multicast_in_1_valid,
            
            ila_x_in_1           => ila_x_in_1,
            ila_x_in_1_valid     => ila_x_in_1_valid,
            
            ila_y_in_1           => ila_y_in_1,
            ila_y_in_1_valid     => ila_y_in_1_valid,
            
            ila_multicast_out_2                => ila_multicast_out_2,
            ila_multicast_out_2_valid          => ila_multicast_out_2_valid,
            
            ila_x_out_2           => ila_x_out_2,
            ila_x_out_2_valid     => ila_x_out_2_valid,
            
            ila_y_out_2           => ila_y_out_2,
            ila_y_out_2_valid     => ila_y_out_2_valid
        );
      
    MULTICAST_ROUTER_0_ILA_GEN: if (ENABLE_MULTICAST_ROUTER_0_ILA = True) generate
        ila_multicast_in_1_dest              <= get_dest_coord(ila_multicast_in_1);
        ila_multicast_in_1_multicast_coord   <= get_multicast_coord(ila_multicast_in_1);
        ila_multicast_in_1_matrix_coord      <= get_matrix_coord(ila_multicast_in_1);

        ila_multicast_in_1_x_dest         <= ila_multicast_in_1_dest(X_INDEX);
        ila_multicast_in_1_y_dest         <= ila_multicast_in_1_dest(Y_INDEX);
        ila_multicast_in_1_multicast_x    <= ila_multicast_in_1_multicast_coord(X_INDEX);
        ila_multicast_in_1_multicast_y    <= ila_multicast_in_1_multicast_coord(Y_INDEX);
        ila_multicast_in_1_ready(0)       <= get_ready_flag(ila_multicast_in_1);
        ila_multicast_in_1_result(0)      <= get_result_flag(ila_multicast_in_1);
        ila_multicast_in_1_matrix_type    <= get_matrix_type(ila_multicast_in_1);
        ila_multicast_in_1_matrix_x       <= ila_multicast_in_1_matrix_coord(X_INDEX);
        ila_multicast_in_1_matrix_y       <= ila_multicast_in_1_matrix_coord(Y_INDEX);
        ila_multicast_in_1_matrix_element <= get_matrix_element(ila_multicast_in_1);

        MULTICAST_ROUTER_0_ILA: multicast_ila
           port map (
               clk         => clkdiv2,
               
               probe0      => ila_multicast_in_1_x_dest,
               probe1      => ila_multicast_in_1_y_dest,
               probe2      => ila_multicast_in_1_multicast_x,
               probe3      => ila_multicast_in_1_multicast_y,
               probe4      => ila_multicast_in_1_ready,
               probe5      => ila_multicast_in_1_result,
               probe6      => ila_multicast_in_1_matrix_type,
               probe7      => ila_multicast_in_1_matrix_x,
               probe8      => ila_multicast_in_1_matrix_y,
               probe9      => ila_multicast_in_1_matrix_element,
               probe10(0)  => ila_multicast_in_1_valid
           );
           
        ila_multicast_out_2_dest              <= get_dest_coord(ila_multicast_out_2);
        ila_multicast_out_2_multicast_coord   <= get_multicast_coord(ila_multicast_out_2);
        ila_multicast_out_2_matrix_coord      <= get_matrix_coord(ila_multicast_out_2);
    
        ila_multicast_out_2_x_dest         <= ila_multicast_out_2_dest(X_INDEX);
        ila_multicast_out_2_y_dest         <= ila_multicast_out_2_dest(Y_INDEX);
        ila_multicast_out_2_multicast_x    <= ila_multicast_out_2_multicast_coord(X_INDEX);
        ila_multicast_out_2_multicast_y    <= ila_multicast_out_2_multicast_coord(Y_INDEX);
        ila_multicast_out_2_ready(0)       <= get_ready_flag(ila_multicast_out_2);
        ila_multicast_out_2_result(0)      <= get_result_flag(ila_multicast_out_2);
        ila_multicast_out_2_matrix_type    <= get_matrix_type(ila_multicast_out_2);
        ila_multicast_out_2_matrix_x       <= ila_multicast_out_2_matrix_coord(X_INDEX);
        ila_multicast_out_2_matrix_y       <= ila_multicast_out_2_matrix_coord(Y_INDEX);
        ila_multicast_out_2_matrix_element <= get_matrix_element(ila_multicast_out_2);
    
        MULTICAST_ROUTER_1_ILA: multicast_ila
           port map (
               clk         => clkdiv2,
               
               probe0      => ila_multicast_out_2_x_dest,
               probe1      => ila_multicast_out_2_y_dest,
               probe2      => ila_multicast_out_2_multicast_x,
               probe3      => ila_multicast_out_2_multicast_y,
               probe4      => ila_multicast_out_2_ready,
               probe5      => ila_multicast_out_2_result,
               probe6      => ila_multicast_out_2_matrix_type,
               probe7      => ila_multicast_out_2_matrix_x,
               probe8      => ila_multicast_out_2_matrix_y,
               probe9      => ila_multicast_out_2_matrix_element,
               probe10(0)  => ila_multicast_out_2_valid
           );
    end generate MULTICAST_ROUTER_0_ILA_GEN;
    
    HOPLITE_ROUTER_0_ILA_GEN: if (ENABLE_HOPLITE_ROUTER_0_ILA = True) generate  
        ila_x_in_1_dest              <= get_dest_coord(ila_x_in_1);
        ila_x_in_1_multicast_coord   <= get_multicast_coord(ila_x_in_1);
        ila_x_in_1_matrix_coord      <= get_matrix_coord(ila_x_in_1);

        ila_x_in_1_x_dest         <= ila_x_in_1_dest(X_INDEX);
        ila_x_in_1_y_dest         <= ila_x_in_1_dest(Y_INDEX);
        ila_x_in_1_multicast_x    <= ila_x_in_1_multicast_coord(X_INDEX);
        ila_x_in_1_multicast_y    <= ila_x_in_1_multicast_coord(Y_INDEX);
        ila_x_in_1_ready(0)       <= get_ready_flag(ila_x_in_1);
        ila_x_in_1_result(0)      <= get_result_flag(ila_x_in_1);
        ila_x_in_1_matrix_type    <= get_matrix_type(ila_x_in_1);
        ila_x_in_1_matrix_x       <= ila_x_in_1_matrix_coord(X_INDEX);
        ila_x_in_1_matrix_y       <= ila_x_in_1_matrix_coord(Y_INDEX);
        ila_x_in_1_matrix_element <= get_matrix_element(ila_x_in_1);

        HOPLITE_ROUTER_0_X_ILA: hoplite_router_ila
            port map (
                clk         => clkdiv2,
                
                probe0      => ila_x_in_1_x_dest,
                probe1      => ila_x_in_1_y_dest,
                probe2      => ila_x_in_1_multicast_x,
                probe3      => ila_x_in_1_multicast_y,
                probe4      => ila_x_in_1_ready,
                probe5      => ila_x_in_1_result,
                probe6      => ila_x_in_1_matrix_type,
                probe7      => ila_x_in_1_matrix_x,
                probe8      => ila_x_in_1_matrix_y,
                probe9      => ila_x_in_1_matrix_element,
                probe10(0)  => ila_x_in_1_valid
            );
    
        ila_y_in_1_dest              <= get_dest_coord(ila_y_in_1);
        ila_y_in_1_multicast_coord   <= get_multicast_coord(ila_y_in_1);
        ila_y_in_1_matrix_coord      <= get_matrix_coord(ila_y_in_1);

        ila_y_in_1_x_dest         <= ila_y_in_1_dest(X_INDEX);
        ila_y_in_1_y_dest         <= ila_y_in_1_dest(Y_INDEX);
        ila_y_in_1_multicast_x    <= ila_y_in_1_multicast_coord(X_INDEX);
        ila_y_in_1_multicast_y    <= ila_y_in_1_multicast_coord(Y_INDEX);
        ila_y_in_1_ready(0)       <= get_ready_flag(ila_y_in_1);
        ila_y_in_1_result(0)      <= get_result_flag(ila_y_in_1);
        ila_y_in_1_matrix_type    <= get_matrix_type(ila_y_in_1);
        ila_y_in_1_matrix_x       <= ila_y_in_1_matrix_coord(X_INDEX);
        ila_y_in_1_matrix_y       <= ila_y_in_1_matrix_coord(Y_INDEX);
        ila_y_in_1_matrix_element <= get_matrix_element(ila_y_in_1);

        HOPLITE_ROUTER_0_Y_ILA: hoplite_router_ila
            port map (
                clk         => clkdiv2,
                
                probe0      => ila_y_in_1_x_dest,
                probe1      => ila_y_in_1_y_dest,
                probe2      => ila_y_in_1_multicast_x,
                probe3      => ila_y_in_1_multicast_y,
                probe4      => ila_y_in_1_ready,
                probe5      => ila_y_in_1_result,
                probe6      => ila_y_in_1_matrix_type,
                probe7      => ila_y_in_1_matrix_x,
                probe8      => ila_y_in_1_matrix_y,
                probe9      => ila_y_in_1_matrix_element,
                probe10(0)  => ila_y_in_1_valid
            );
                        
        ila_x_out_2_dest              <= get_dest_coord(ila_x_out_2);
        ila_x_out_2_multicast_coord   <= get_multicast_coord(ila_x_out_2);
        ila_x_out_2_matrix_coord      <= get_matrix_coord(ila_x_out_2);

        ila_x_out_2_x_dest         <= ila_x_out_2_dest(X_INDEX);
        ila_x_out_2_y_dest         <= ila_x_out_2_dest(Y_INDEX);
        ila_x_out_2_multicast_x    <= ila_x_out_2_multicast_coord(X_INDEX);
        ila_x_out_2_multicast_y    <= ila_x_out_2_multicast_coord(Y_INDEX);
        ila_x_out_2_ready(0)       <= get_ready_flag(ila_x_out_2);
        ila_x_out_2_result(0)      <= get_result_flag(ila_x_out_2);
        ila_x_out_2_matrix_type    <= get_matrix_type(ila_x_out_2);
        ila_x_out_2_matrix_x       <= ila_x_out_2_matrix_coord(X_INDEX);
        ila_x_out_2_matrix_y       <= ila_x_out_2_matrix_coord(Y_INDEX);
        ila_x_out_2_matrix_element <= get_matrix_element(ila_x_out_2);

        HOPLITE_ROUTER_1_X_ILA: hoplite_router_ila
            port map (
                clk         => clkdiv2,
                
                probe0      => ila_x_out_2_x_dest,
                probe1      => ila_x_out_2_y_dest,
                probe2      => ila_x_out_2_multicast_x,
                probe3      => ila_x_out_2_multicast_y,
                probe4      => ila_x_out_2_ready,
                probe5      => ila_x_out_2_result,
                probe6      => ila_x_out_2_matrix_type,
                probe7      => ila_x_out_2_matrix_x,
                probe8      => ila_x_out_2_matrix_y,
                probe9      => ila_x_out_2_matrix_element,
                probe10(0)  => ila_x_out_2_valid
            );
    
        ila_y_out_2_dest              <= get_dest_coord(ila_y_out_2);
        ila_y_out_2_multicast_coord   <= get_multicast_coord(ila_y_out_2);
        ila_y_out_2_matrix_coord      <= get_matrix_coord(ila_y_out_2);

        ila_y_out_2_x_dest         <= ila_y_out_2_dest(X_INDEX);
        ila_y_out_2_y_dest         <= ila_y_out_2_dest(Y_INDEX);
        ila_y_out_2_multicast_x    <= ila_y_out_2_multicast_coord(X_INDEX);
        ila_y_out_2_multicast_y    <= ila_y_out_2_multicast_coord(Y_INDEX);
        ila_y_out_2_ready(0)       <= get_ready_flag(ila_y_out_2);
        ila_y_out_2_result(0)      <= get_result_flag(ila_y_out_2);
        ila_y_out_2_matrix_type    <= get_matrix_type(ila_y_out_2);
        ila_y_out_2_matrix_x       <= ila_y_out_2_matrix_coord(X_INDEX);
        ila_y_out_2_matrix_y       <= ila_y_out_2_matrix_coord(Y_INDEX);
        ila_y_out_2_matrix_element <= get_matrix_element(ila_y_out_2);

        HOPLITE_ROUTER_1_Y_ILA: hoplite_router_ila
            port map (
                clk         => clkdiv2,
                
                probe0      => ila_y_out_2_x_dest,
                probe1      => ila_y_out_2_y_dest,
                probe2      => ila_y_out_2_multicast_x,
                probe3      => ila_y_out_2_multicast_y,
                probe4      => ila_y_out_2_ready,
                probe5      => ila_y_out_2_result,
                probe6      => ila_y_out_2_matrix_type,
                probe7      => ila_y_out_2_matrix_x,
                probe8      => ila_y_out_2_matrix_y,
                probe9      => ila_y_out_2_matrix_element,
                probe10(0)  => ila_y_out_2_valid
            );
    end generate HOPLITE_ROUTER_0_ILA_GEN;

end Behavioral;
