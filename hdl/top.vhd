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
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity top is
    Port ( btnCpuReset  : in STD_LOGIC;
           clk          : in STD_LOGIC;
           led          : out STD_LOGIC_VECTOR(15 downto 0);
           RGB1_Red     : out STD_LOGIC;
           RGB1_Green   : out STD_LOGIC;
           RGB1_Blue    : out STD_LOGIC;
           RGB2_Red     : out STD_LOGIC);
end top;

architecture Behavioral of top is

    component system
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

begin

    CORE_1 : system
        port map (
            clk         => clk,
            resetn      => btnCpuReset,
            led         => led,
            RGB_LED     => RGB1_Red,
            out_byte_en => open,
            out_byte    => open,
            trap        => open
        );
        
    CORE_2 : system
        port map (
            clk         => clk,
            resetn      => btnCpuReset,
            led         => open,
            RGB_LED     => RGB1_Green,
            out_byte_en => open,
            out_byte    => open,
            trap        => open
        );
        
    CORE_3 : system
        port map (
            clk         => clk,
            resetn      => btnCpuReset,
            led         => open,
            RGB_LED     => RGB1_Blue,
            out_byte_en => open,
            out_byte    => open,
            trap        => open
        );
        
    CORE_4 : system
        port map (
            clk         => clk,
            resetn      => btnCpuReset,
            led         => open,
            RGB_LED     => RGB2_Red,
            out_byte_en => open,
            out_byte    => open,
            trap        => open
        );

end Behavioral;
