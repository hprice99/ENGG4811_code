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

entity top is
    Generic (
        -- Fox's algorithm network paramters
        FOX_NETWORK_STAGES  : integer := 2;
        FOX_NETWORK_NODES   : integer := 4
    );
    Port ( 
           reset_n  : in STD_LOGIC;
           clk      : in STD_LOGIC;
           LED      : out STD_LOGIC_VECTOR((FOX_NETWORK_NODES-1) downto 0)
    );
    -- TODO Expose out_char and out_matrix as output port
end top;

architecture Behavioral of top is

    component node
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
            MATRIX_SIZE     : integer := 32;
            MATRIX_FILE     : string  := "none";

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
    end component node;
    
    -- Constants
    constant NETWORK_ROWS   : integer := 2;
    constant NETWORK_COLS   : integer := 2;
    constant NETWORK_NODES  : integer := NETWORK_ROWS * NETWORK_COLS;

    -- Fox's algorithm network paramters
    -- constant FOX_NETWORK_ROWS    : integer := 2;
    -- constant FOX_NETWORK_COLS    : integer := 2;
    -- constant FOX_NETWORK_NODES   : integer := FOX_NETWORK_ROWS * FOX_NETWORK_COLS;

    -- Result node parameters
    -- TODO Implement result node
    constant RESULT_X_COORD  : integer := 0;
    constant RESULT_Y_COORD  : integer := 0;

    -- Size of message data in packets
    constant COORD_BITS             : integer := ceil_log2(max(NETWORK_ROWS, NETWORK_COLS));
    constant MULTICAST_GROUP_BITS   : integer := 1;
    constant DONE_FLAG_BITS         : integer := 1;
    constant RESULT_FLAG_BITS       : integer := 1;
    constant MATRIX_TYPE_BITS       : integer := 1;
    constant MATRIX_COORD_BITS      : integer := 8;
    constant MATRIX_ELEMENT_BITS    : integer := 32;
    constant BUS_WIDTH              : integer := 
            2*COORD_BITS + MULTICAST_GROUP_BITS + DONE_FLAG_BITS + 
            RESULT_FLAG_BITS + MATRIX_TYPE_BITS + 2*MATRIX_COORD_BITS + 
            MATRIX_ELEMENT_BITS;

    -- Matrix parameters
    constant MATRIX_SIZE    : integer := 2;

    -- NIC parameters
    constant FIFO_DEPTH : integer := 64;

    constant X_INDEX    : integer := 0;
    constant Y_INDEX    : integer := 1;

    -- Custom types
    type t_Coordinate is array (0 to 1) of std_logic_vector((COORD_BITS-1) downto 0);
    type t_Destination is array(0 to (NETWORK_COLS-1), 0 to (NETWORK_ROWS-1)) of t_Coordinate;
    type t_Message is array (0 to (NETWORK_COLS-1), 0 to (NETWORK_ROWS-1)) of std_logic_vector((BUS_WIDTH-1) downto 0);
    type t_MessageValid is array (0 to (NETWORK_COLS-1), 0 to (NETWORK_ROWS-1)) of std_logic;
    type t_Char is array (0 to (NETWORK_COLS-1), 0 to (NETWORK_ROWS-1)) of std_logic_vector(7 downto 0);
    type t_Matrix is array (0 to (NETWORK_COLS-1), 0 to (NETWORK_ROWS-1)) of std_logic_vector(31 downto 0);
    
    -- Array of message interfaces between nodes
    signal x_messages_out, y_messages_out : t_Message;
    signal x_messages_out_valid, y_messages_out_valid : t_MessageValid;
    signal x_messages_in, y_messages_in : t_Message;
    signal x_messages_in_valid, y_messages_in_valid : t_MessageValid;
    
    -- UART output
    signal out_char     : t_Char;
    signal out_char_en  : t_MessageValid;

    -- Matrix output
    signal out_matrix           : t_Matrix;
    signal out_matrix_en        : t_MessageValid;
    signal out_matrix_end_row   : t_MessageValid;
    signal out_matrix_end       : t_MessageValid;

    constant DIVIDE_ENABLED     : std_logic := '0';
    constant MULTIPLY_ENABLED   : std_logic := '1';
    constant FOX_FIRMWARE       : string := "firmware_hoplite.hex";

    constant MEM_SIZE               : integer := 4096;

begin

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
        begin
            -- Connect in and out messages
            x_messages_in(curr_x, curr_y)       <= x_messages_out(prev_x, curr_y);
            x_messages_in_valid(curr_x, curr_y) <= x_messages_out_valid(prev_x, curr_y);

            y_messages_in(curr_x, curr_y)       <= y_messages_out(curr_x, next_y);
            y_messages_in_valid(curr_x, curr_y) <= y_messages_out_valid(curr_x, next_y);
        
            -- Instantiate node
            -- TODO Instantiate result node
            FOX_NODE: node
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
                    MATRIX_SIZE     => MATRIX_SIZE,
                    -- TODO Implement matrix initialisation files for each node
                    MATRIX_FILE     => "none",

                    -- NIC parameters
                    FIFO_DEPTH      => FIFO_DEPTH,
                    
                    -- PicoRV32 core parameters
                    DIVIDE_ENABLED     => DIVIDE_ENABLED,
                    MULTIPLY_ENABLED   => MULTIPLY_ENABLED,
                    FIRMWARE           => FOX_FIRMWARE,
                    MEM_SIZE           => MEM_SIZE
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
        end generate NETWORK_COL_GEN;
    end generate NETWORK_ROW_GEN;

    
end Behavioral;
