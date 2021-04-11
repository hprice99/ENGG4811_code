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
           btnCpuReset  : in STD_LOGIC;
           clk          : in STD_LOGIC;
           led          : out STD_LOGIC_VECTOR(15 downto 0);
           RGB1_Red     : out STD_LOGIC;
           RGB1_Green   : out STD_LOGIC;
           RGB1_Blue    : out STD_LOGIC;
           RGB2_Red     : out STD_LOGIC
    );
end top;

architecture Behavioral of top is

    component system
        generic (
             USE_ILA : integer := 1
        );
        port (
            clk         : in std_logic;
            resetn      : in std_logic;
            led         : out std_logic_vector(15 downto 0);
            RGB_LED     : out std_logic;
            out_byte_en : out std_logic;
            out_byte    : out std_logic_vector(7 downto 0);
            trap        : out std_logic
        );
    end component system;
    
    -- signal core1_out_byte_en : std_logic;
    
    -- signal green_1_led, blue_1_led, red_2_led : std_logic;

begin

    CORE_1 : system
        generic map(
           USE_ILA     => 1
        )
        port map (
            clk         => clk,
            resetn      => btnCpuReset,
            led         => led,
            RGB_LED     => RGB1_Red,
            -- out_byte_en => core1_out_byte_en,
            out_byte_en => open,
            out_byte    => open,
            trap        => open
        );
        
    CORE_2 : system
        generic map(
           USE_ILA     => 1
        )
        port map (
            clk         => clk,
            resetn      => btnCpuReset,
            led         => open,
            -- RGB_LED     => green_1_led,
            RGB_LED     => RGB1_Green,
            out_byte_en => open,
            out_byte    => open,
            trap        => open
        );
        
    -- RGB1_Green <= core1_out_byte_en and green_1_led;
        
    CORE_3 : system
        generic map(
           USE_ILA     => 1
        )
        port map (
            clk         => clk,
            resetn      => btnCpuReset,
            led         => open,
            -- RGB_LED     => blue_1_led,
            RGB_LED     => RGB1_Blue,
            out_byte_en => open,
            out_byte    => open,
            trap        => open
        );
        
    -- RGB1_Blue <= core1_out_byte_en and blue_1_led;
        
    CORE_4 : system
        generic map(
           USE_ILA     => 1
        )
        port map (
            clk         => clk,
            resetn      => btnCpuReset,
            led         => open,
            -- RGB_LED     => red_2_led,
            RGB_LED     => RGB2_Red,
            out_byte_en => open,
            out_byte    => open,
            trap        => open
        );
    
    -- RGB2_Red <= core1_out_byte_en and red_2_led;

end Behavioral;
