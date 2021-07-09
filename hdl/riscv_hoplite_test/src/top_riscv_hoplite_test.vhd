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
    Port ( 
           CPU_RESETN   : in STD_LOGIC;
           CLK_100MHZ   : in STD_LOGIC;
           SW           : in STD_LOGIC_VECTOR(3 downto 0);
           LED          : out STD_LOGIC_VECTOR(3 downto 0)
    );
end top;

architecture Behavioral of top is

    component node_led
        generic (
            NETWORK_ROWS    : integer := 2;
            NETWORK_COLS    : integer := 2;   
            NETWORK_NODES   : integer := 4;
        
            X_COORD         : integer := 0;
            Y_COORD         : integer := 0;
            COORD_BITS      : integer := 2;
            MESSAGE_BITS    : integer := 32;
            BUS_WIDTH       : integer := 8;

            DIVIDE_ENABLED     : std_logic := '0';
            MULTIPLY_ENABLED   : std_logic := '1';
            FIRMWARE           : string    := "firmware.hex";
            MEM_SIZE           : integer   := 4096
        );
        port (
            clk                 : in std_logic;
            reset_n             : in std_logic;
            
            switch              : in std_logic;
            LED                 : out std_logic_vector((NETWORK_NODES-1) downto 0);
            
            x_in                : in STD_LOGIC_VECTOR((BUS_WIDTH-1) downto 0);
            x_in_valid          : in STD_LOGIC;
            y_in                : in STD_LOGIC_VECTOR((BUS_WIDTH-1) downto 0);
            y_in_valid          : in STD_LOGIC;
            
            x_out               : out STD_LOGIC_VECTOR((BUS_WIDTH-1) downto 0);
            x_out_valid         : out STD_LOGIC;
            y_out               : out STD_LOGIC_VECTOR((BUS_WIDTH-1) downto 0);
            y_out_valid         : out STD_LOGIC
        );
    end component node_led;

    -- Size of message data in packets
    constant MESSAGE_BITS       : integer := 32;
    
    -- Constants
    constant NETWORK_ROWS   : integer := 2;
    constant NETWORK_COLS   : integer := 2;
    constant NETWORK_NODES  : integer := NETWORK_ROWS * NETWORK_COLS;
    constant COORD_BITS     : integer := ceil_log2(max(NETWORK_ROWS, NETWORK_COLS));
    constant BUS_WIDTH      : integer := 2 * COORD_BITS + MESSAGE_BITS;
    
    constant X_INDEX    : integer := 0;
    constant Y_INDEX    : integer := 1;
    
    -- Custom types
    type t_Coordinate is array (0 to 1) of std_logic_vector((COORD_BITS-1) downto 0);
    type t_Destination is array(0 to (NETWORK_COLS-1), 0 to (NETWORK_ROWS-1)) of t_Coordinate;
    type t_Message is array (0 to (NETWORK_COLS-1), 0 to (NETWORK_ROWS-1)) of std_logic_vector((BUS_WIDTH-1) downto 0);
    type t_MessageValid is array (0 to (NETWORK_COLS-1), 0 to (NETWORK_ROWS-1)) of std_logic;
    
    -- Array of message interfaces between nodes
    signal x_messages_out, y_messages_out : t_Message;
    signal x_messages_out_valid, y_messages_out_valid : t_MessageValid;
    signal x_messages_in, y_messages_in : t_Message;
    signal x_messages_in_valid, y_messages_in_valid : t_MessageValid;
    
    signal clkdiv2 : std_logic := '0';
    
    constant LED_NODE_ROW   : integer := 0;
    constant LED_NODE_COL   : integer := 0;   
    
    constant DIVIDE_ENABLED : std_logic := '0';
    constant MULTIPLY_ENABLED   : std_logic := '1';
    
    constant SWITCH_NODE_FIRMWARE   : string := "firmware_riscv_hoplite_test_switch.hex";
    constant LED_NODE_FIRMWARE      : string := "firmware_riscv_hoplite_test_led.hex";
    constant MEM_SIZE   : integer := 1024;
    
    signal reset_n : std_logic;

begin

    -- Clock divider
    CLOCK_DIVIDER: process (CLK_100MHZ)
    begin
        if (rising_edge(CLK_100MHZ)) then   
            clkdiv2 <= not clkdiv2;
        end if;
    end process CLOCK_DIVIDER;
    
    reset_n <= CPU_RESETN;
    
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
            
            y_messages_in(curr_x, curr_y)       <= y_messages_out(curr_x, prev_y);
            y_messages_in_valid(curr_x, curr_y) <= y_messages_out_valid(curr_x, prev_y);
        
            -- Instantiate node
            LED_NODE_GEN: if (i = LED_NODE_COL and j = LED_NODE_COL) generate
                LED_NODE: node_led
                    generic map (
                        NETWORK_ROWS    => NETWORK_ROWS,
                        NETWORK_COLS    => NETWORK_COLS,
                        NETWORK_NODES   => NETWORK_NODES,
                    
                        X_COORD         => curr_x,
                        Y_COORD         => curr_y,
                        COORD_BITS      => COORD_BITS,
                        MESSAGE_BITS    => MESSAGE_BITS,
                        BUS_WIDTH       => BUS_WIDTH,
                        
                        DIVIDE_ENABLED      => DIVIDE_ENABLED,
                        MULTIPLY_ENABLED    => MULTIPLY_ENABLED,
                        FIRMWARE            => LED_NODE_FIRMWARE,
                        MEM_SIZE            => MEM_SIZE
                    )
                    port map (
                        clk                 => clkdiv2,
                        reset_n             => reset_n,
                        
                        switch              =>  SW(node_number),
                        LED                 =>  LED,
                        
                        -- Messages incoming to router
                        x_in                => x_messages_in(curr_x, curr_y),
                        x_in_valid          => x_messages_in_valid(curr_x, curr_y),                  
                        y_in                => y_messages_in(curr_x, curr_y),
                        y_in_valid          => y_messages_in_valid(curr_x, curr_y),
                        
                        -- Messages outgoing from router
                        x_out               => x_messages_out(curr_x, curr_y),
                        x_out_valid         => x_messages_out_valid(curr_x, curr_y),
                        y_out               => y_messages_out(curr_x, curr_y),
                        y_out_valid         => y_messages_out_valid(curr_x, curr_y)
                    );
            end generate LED_NODE_GEN;
            
            SWITCH_NODE_GEN: if (not (i = LED_NODE_COL and j = LED_NODE_COL)) generate
                SWITCH_NODE: node_led
                    generic map (
                        NETWORK_ROWS    => NETWORK_ROWS,
                        NETWORK_COLS    => NETWORK_COLS,
                        NETWORK_NODES   => NETWORK_NODES,
                    
                        X_COORD         => curr_x,
                        Y_COORD         => curr_y,
                        COORD_BITS      => COORD_BITS,
                        MESSAGE_BITS    => MESSAGE_BITS,
                        BUS_WIDTH       => BUS_WIDTH,
                        
                        DIVIDE_ENABLED      => DIVIDE_ENABLED,
                        MULTIPLY_ENABLED    => MULTIPLY_ENABLED,
                        FIRMWARE            => SWITCH_NODE_FIRMWARE,
                        MEM_SIZE            => MEM_SIZE
                    )
                    port map (
                        clk                 => clkdiv2,
                        reset_n             => reset_n,
                        
                        switch              =>  SW(node_number),
                        LED                 =>  open,
                        
                        -- Messages incoming to router
                        x_in                => x_messages_in(curr_x, curr_y),
                        x_in_valid          => x_messages_in_valid(curr_x, curr_y),                  
                        y_in                => y_messages_in(curr_x, curr_y),
                        y_in_valid          => y_messages_in_valid(curr_x, curr_y),
                        
                        -- Messages outgoing from router
                        x_out               => x_messages_out(curr_x, curr_y),
                        x_out_valid         => x_messages_out_valid(curr_x, curr_y),
                        y_out               => y_messages_out(curr_x, curr_y),
                        y_out_valid         => y_messages_out_valid(curr_x, curr_y)
                    );
            end generate SWITCH_NODE_GEN;
        end generate NETWORK_COL_GEN;
    end generate NETWORK_ROW_GEN;

    
end Behavioral;
