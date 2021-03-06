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
           CPU_RESETN   : in std_logic;
           CLK_100MHZ   : in std_logic;
           SW           : in std_logic_vector(3 downto 0);
           LED          : out std_logic_vector(15 downto 0);
           LED16_B      : out std_logic;
           LED16_G      : out std_logic;
           LED17_R      : out std_logic;
           LED17_B      : out std_logic
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
    
    component pipeline
        generic (
            STAGES  : integer := 10
        );
        port (
            clk     : in std_logic;
            d_in    : in std_logic;
            d_out   : out std_logic
        );
    end component pipeline;
    
    signal sw0_pipelined, sw1_pipelined, sw2_pipelined, sw3_pipelined : std_logic;
    constant switch_pipeline_stages : integer := 30;
    constant mem_size : integer := 1024;

begin

    SW0_PIPELINE : pipeline
        generic map (
            STAGES  => switch_pipeline_stages
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
           FIRMWARE         => "firmware.hex",
           MEM_SIZE         => mem_size
        )
        port map (
            clk                         => CLK_100MHZ,
            resetn                      => CPU_RESETN,
            -- sw                 => sw(0),
            sw                          => sw0_pipelined,
            led                         => led,
            RGB_LED                     => LED16_B,
            out_byte_en                 => open,
            out_byte                    => open,
            out_matrix_en               => open,
            out_matrix                  => open,
            out_matrix_end_row          => open,
            out_matrix_end              => open,
            out_matrix_position_en      => open,
            out_matrix_position         => open,
            trap                        => open
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
            -- sw                 => sw(1),
            sw                          => sw1_pipelined,
            led                         => open,
            RGB_LED                     => LED16_G,
            out_byte_en                 => open,
            out_byte                    => open,
            out_matrix_en               => open,
            out_matrix                  => open,
            out_matrix_end_row          => open,
            out_matrix_end              => open,
            out_matrix_position_en      => open,
            out_matrix_position         => open,
            trap                        => open
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
            -- sw                 => sw(2),
            sw                          => sw2_pipelined,
            led                         => open,
            RGB_LED                     => LED17_R,
            out_byte_en                 => open,
            out_byte                    => open,
            out_matrix_en               => open,
            out_matrix                  => open,
            out_matrix_end_row          => open,
            out_matrix_end              => open,
            out_matrix_position_en      => open,
            out_matrix_position         => open,
            trap                        => open
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
            -- sw                 => sw(3),
            sw                          => sw3_pipelined,
            led                         => open,
            RGB_LED                     => LED17_B,
            out_byte_en                 => open,
            out_byte                    => open,
            out_matrix_en               => open,
            out_matrix                  => open,
            out_matrix_end_row          => open,
            out_matrix_end              => open,
            out_matrix_position_en      => open,
            out_matrix_position         => open,
            trap                        => open
        );

end Behavioral;
