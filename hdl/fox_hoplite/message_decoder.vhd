----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 07/04/2021 09:50:10 PM
-- Design Name: 
-- Module Name: message_decoder - Behavioral
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

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity message_decoder is
    Generic (
        COORD_BITS              : integer := 2;
        MULTICAST_GROUP_BITS    : integer := 1;
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
        
        x_coord_out         : out std_logic_vector((COORD_BITS-1) downto 0);
        y_coord_out         : out std_logic_vector((COORD_BITS-1) downto 0);
        multicast_group_out : out std_logic_vector((MULTICAST_GROUP_BITS-1) downto 0);
        done_flag_out       : out std_logic;
        result_flag_out     : out std_logic;
        matrix_type_out     : out std_logic_vector((MATRIX_TYPE_BITS-1) downto 0);
        matrix_x_coord_out  : out std_logic_vector((MATRIX_COORD_BITS-1) downto 0);
        matrix_y_coord_out  : out std_logic_vector((MATRIX_COORD_BITS-1) downto 0);
        matrix_element_out  : out std_logic_vector((MATRIX_ELEMENT_BITS-1) downto 0);

        packet_out_valid    : out std_logic;
        packet_read         : in std_logic
    );
end message_decoder;

architecture Behavioral of message_decoder is

    signal latest_packet    : std_logic_vector((BUS_WIDTH-1) downto 0);

    constant X_COORD_START  : integer := 0;
    constant X_COORD_END    : integer := X_COORD_START + COORD_BITS - 1;

    constant Y_COORD_START  : integer := X_COORD_END + 1;
    constant Y_COORD_END    : integer := Y_COORD_START + COORD_BITS - 1;

    constant MULTICAST_GROUP_START  : integer := Y_COORD_END + 1;
    constant MULTICAST_GROUP_END    : integer := MULTICAST_GROUP_START + MULTICAST_GROUP_BITS - 1;

    constant DONE_FLAG_BIT          : integer := MULTICAST_GROUP_END + 1;

    constant RESULT_FLAG_BIT        : integer := DONE_FLAG_BIT + 1;

    constant MATRIX_TYPE_START      : integer := RESULT_FLAG_BIT + 1;
    constant MATRIX_TYPE_END        : integer := MATRIX_TYPE_START + MATRIX_TYPE_BITS - 1;

    constant MATRIX_X_COORD_START   : integer := MATRIX_TYPE_END + 1;
    constant MATRIX_X_COORD_END     : integer := MATRIX_X_COORD_START + MATRIX_COORD_BITS - 1;

    constant MATRIX_Y_COORD_START   : integer := MATRIX_X_COORD_END + 1;
    constant MATRIX_Y_COORD_END     : integer := MATRIX_Y_COORD_START + MATRIX_COORD_BITS - 1;

    constant MATRIX_ELEMENT_START   : integer := MATRIX_Y_COORD_END + 1;
    constant MATRIX_ELEMENT_END     : integer := MATRIX_ELEMENT_START + MATRIX_ELEMENT_BITS - 1;

begin
    latest_packet       <= packet_in;

    -- Message format 0 -- x_dest | y_dest | multicast_group | done | result | matrix | matrix_x_coord | matrix_y_coord | matrix_element -- (BUS_WIDTH-1)
    x_coord_out         <= latest_packet(X_COORD_END downto X_COORD_START);
    y_coord_out         <= latest_packet(Y_COORD_END downto Y_COORD_START);
    multicast_group_out <= latest_packet(MULTICAST_GROUP_END downto MULTICAST_GROUP_START);
    done_flag_out       <= latest_packet(DONE_FLAG_BIT);
    result_flag_out     <= latest_packet(RESULT_FLAG_BIT);
    matrix_type_out     <= latest_packet(MATRIX_TYPE_END downto MATRIX_TYPE_START);
    matrix_x_coord_out  <= latest_packet(MATRIX_X_COORD_END downto MATRIX_X_COORD_START);
    matrix_y_coord_out  <= latest_packet(MATRIX_Y_COORD_END downto MATRIX_Y_COORD_START);
    matrix_element_out  <= latest_packet(MATRIX_ELEMENT_END downto MATRIX_ELEMENT_START);
    
    -- Hold packet_out_valid high from when packet_in_valid is high to when the message is read, then reset
    VALID_FF: process (clk)
    begin
        if (rising_edge(clk)) then
            if (reset_n = '0') then
                packet_out_valid <= '0';
            else
                if (packet_read <= '1') then
                    packet_out_valid <= '0';
                elsif (packet_in_valid = '1') then
                    packet_out_valid <= '1';
                end if;
            end if;
        end if;
    end process VALID_FF;

end Behavioral;
