----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 05/01/2021 07:14:16 PM
-- Design Name: 
-- Module Name: hoplite_tb_node - Behavioral
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
use IEEE.NUMERIC_STD.ALL;
use IEEE.math_real.all;

use STD.textio.all;
use IEEE.std_logic_textio.all;

library xil_defaultlib;
use xil_defaultlib.hoplite_network_tb_defs.all;

entity hoplite_tb_node is
    Generic (
        X_COORD     : integer := 0;
        Y_COORD     : integer := 0;
        COORD_BITS  : integer := 2;
        BUS_WIDTH   : integer := 8
    );
    Port ( 
        clk                 : in STD_LOGIC;
        reset_n             : in STD_LOGIC;
        count               : in INTEGER;
        x_dest              : in STD_LOGIC_VECTOR((COORD_BITS-1) downto 0);
        y_dest              : in STD_LOGIC_VECTOR((COORD_BITS-1) downto 0);
        trig                : in STD_LOGIC;
        x_in                : in STD_LOGIC_VECTOR((BUS_WIDTH-1) downto 0);
        x_in_valid          : in STD_LOGIC;
        y_in                : in STD_LOGIC_VECTOR((BUS_WIDTH-1) downto 0);
        y_in_valid          : in STD_LOGIC;
        x_out               : out STD_LOGIC_VECTOR((BUS_WIDTH-1) downto 0);
        x_out_valid         : out STD_LOGIC;
        y_out               : out STD_LOGIC_VECTOR((BUS_WIDTH-1) downto 0);
        y_out_valid         : out STD_LOGIC
    );
end hoplite_tb_node;

architecture Behavioral of hoplite_tb_node is

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
    
    component nic_dual
        generic (
            BUS_WIDTH   : integer := 32;
            FIFO_DEPTH  : integer := 64
        );
        port (
            clk                 : in std_logic;
            reset_n             : in std_logic;
    
            -- Messages from PE to network
            from_pe_valid       : in std_logic;
            from_pe_data        : in std_logic_vector((BUS_WIDTH-1) downto 0);
    
            network_ready       : in std_logic;
            to_network_valid    : out std_logic;
            to_network_data     : out std_logic_vector((BUS_WIDTH-1) downto 0);
            
            pe_to_network_full  : out std_logic;
            pe_to_network_empty : out std_logic;
    
            -- Messages from network to PE
            from_network_valid  : in std_logic;
            from_network_data   : in std_logic_vector((BUS_WIDTH-1) downto 0);
    
            pe_ready            : in std_logic;
            to_pe_valid         : out std_logic;
            to_pe_data          : out std_logic_vector((BUS_WIDTH-1) downto 0);
    
            network_to_pe_full  : out std_logic;
            network_to_pe_empty : out std_logic
        );
    end component nic_dual;

    component hoplite_tb_pe
        generic (
            BUS_WIDTH   : integer := 32;
            X_COORD     : integer := 0;
            Y_COORD     : integer := 0;
            COORD_BITS  : integer := 1
        );
        port (
            clk                  : in STD_LOGIC;
            reset_n              : in STD_LOGIC;
            count                : in integer;
            trig                 : in STD_LOGIC;
            x_dest               : in STD_LOGIC_VECTOR((COORD_BITS-1) downto 0);
            y_dest               : in STD_LOGIC_VECTOR((COORD_BITS-1) downto 0);
            message_out          : out STD_LOGIC_VECTOR ((BUS_WIDTH-1) downto 0);
            message_out_valid    : out STD_LOGIC;
            message_in           : in STD_LOGIC_VECTOR ((BUS_WIDTH-1) downto 0);
            message_in_valid     : in STD_LOGIC
        );
    end component hoplite_tb_pe; 
    
    constant FIFO_DEPTH : integer := 100;
    
    -- Messages from PE to network
    signal pe_message_out       : STD_LOGIC_VECTOR ((BUS_WIDTH-1) downto 0);
    signal pe_message_out_valid : STD_LOGIC;
    
    signal pe_to_network_message    : STD_LOGIC_VECTOR ((BUS_WIDTH-1) downto 0);
    signal pe_to_network_valid      : STD_LOGIC;
    
    signal pe_backpressure      : STD_LOGIC;
    signal router_ready         : STD_LOGIC;
    
    signal pe_to_network_full, pe_to_network_empty   : STD_LOGIC;
    
    -- Messages from network to PE
    signal pe_message_in        : STD_LOGIC_VECTOR ((BUS_WIDTH-1) downto 0);
    signal pe_message_in_valid  : STD_LOGIC;
    
    signal network_to_pe_message    : STD_LOGIC_VECTOR ((BUS_WIDTH-1) downto 0);
    signal network_to_pe_valid      : STD_LOGIC;
    
    signal pe_ready : STD_LOGIC;
    
    signal network_to_pe_full, network_to_pe_empty  : STD_LOGIC;
    
    -- Packets routed out
    signal x_out_d, y_out_d: STD_LOGIC_VECTOR ((BUS_WIDTH-1) downto 0);
    signal x_out_valid_d, y_out_valid_d : STD_LOGIC;
    
    signal print_valid : STD_LOGIC;

begin

    ROUTER: hoplite_router
        generic map (
            BUS_WIDTH   => BUS_WIDTH,
            X_COORD     => X_COORD,
            Y_COORD     => Y_COORD,
            COORD_BITS  => COORD_BITS
        )
        port map (
            clk                 => clk,
            reset_n             => reset_n,
            x_in                => x_in,
            x_in_valid          => x_in_valid,
            y_in                => y_in,
            y_in_valid          => y_in_valid,
            pe_in               => pe_to_network_message,
            pe_in_valid         => pe_to_network_valid,
            x_out               => x_out_d,
            x_out_valid         => x_out_valid_d,
            y_out               => y_out_d,
            y_out_valid         => y_out_valid_d,
            pe_out              => network_to_pe_message,
            pe_out_valid        => network_to_pe_valid,
            pe_backpressure     => pe_backpressure
        );
    
    -- Connect router ports to node ports
    x_out       <= x_out_d;
    x_out_valid <= x_out_valid_d;
    
    y_out       <= y_out_d;
    y_out_valid <= y_out_valid_d;
        
--    OUTPUT: process (reset_n)
--    begin
--        if (reset_n = '0') then
--            x_out       <= (others => '0');
--            x_out_valid <= '0';
            
--            y_out       <= (others => '0');
--            y_out_valid <= '0';
--        else
--            x_out       <= x_out_d;
--            x_out_valid <= x_out_valid_d;
            
--            y_out       <= y_out_d;
--            y_out_valid <= y_out_valid_d;
--        end if;
--    end process OUTPUT;
        
    -- Network interface controller (FIFO for messages to and from PE)
    router_ready <= not pe_backpressure;
    
    PE_READY_TOGGLE: process(count)
    begin
        if (count mod PE_READY_FREQUENCY = 0) then
            pe_ready <= '1';
        else
            pe_ready <= '0';
        end if;
    end process PE_READY_TOGGLE;
        
    NIC: nic_dual
        generic map (
            BUS_WIDTH   => BUS_WIDTH,
            FIFO_DEPTH  => FIFO_DEPTH
        )
        port map (
            clk                 => clk,
            reset_n             => reset_n,
    
            -- Messages from PE to network
            from_pe_valid       => pe_message_out_valid,
            from_pe_data        => pe_message_out,
    
            network_ready       => router_ready,
            to_network_valid    => pe_to_network_valid,
            to_network_data     => pe_to_network_message,
            
            pe_to_network_full  => pe_to_network_full,
            pe_to_network_empty => pe_to_network_empty,
    
            -- Messages from network to PE
            from_network_valid  => network_to_pe_valid,
            from_network_data   => network_to_pe_message,
    
            pe_ready            => pe_ready,
            to_pe_valid         => pe_message_in_valid,
            to_pe_data          => pe_message_in,
    
            network_to_pe_full  => network_to_pe_full,
            network_to_pe_empty => network_to_pe_empty
        );

    print_valid <= x_in_valid or y_in_valid or x_out_valid_d or y_out_valid_d;

    PRINT: process (clk)
        variable my_line : line;
    begin
        if (rising_edge(clk) and reset_n = '1') then
            if (print_valid = '1') then
                write(my_line, string'(HT & "hoplite_tb_node: "));
               
                write(my_line, string'("Node ("));
                write(my_line, X_COORD);
                
                write(my_line, string'(", "));
                write(my_line, Y_COORD);
                write(my_line, string'(")"));
                
                writeline(output, my_line);
            end if;
        
            if (x_in_valid = '1') then
                write(my_line, string'(HT & HT & "x_in: destination = ("));
                write(my_line, to_integer(unsigned(x_in((COORD_BITS-1) downto 0))));
                write(my_line, string'(", "));
                write(my_line, to_integer(unsigned(x_in((2*COORD_BITS-1) downto COORD_BITS))));
                write(my_line, string'("), data = "));
                write(my_line, x_in((BUS_WIDTH-1) downto 2*COORD_BITS));
                write(my_line, string'(", raw = "));
                write(my_line, x_in((BUS_WIDTH-1) downto 0));
                
                writeline(output, my_line);
            end if;
            
            if (y_in_valid = '1') then           
                write(my_line, string'(HT & HT & "y_in: destination = ("));
                write(my_line, to_integer(unsigned(y_in((COORD_BITS-1) downto 0))));
                write(my_line, string'(", "));
                write(my_line, to_integer(unsigned(y_in((2*COORD_BITS-1) downto COORD_BITS))));
                write(my_line, string'("), data = "));
                write(my_line, y_in((BUS_WIDTH-1) downto 2*COORD_BITS));
                write(my_line, string'(", raw = "));
                write(my_line, y_in((BUS_WIDTH-1) downto 0));
                
                writeline(output, my_line);
            end if;
            
            if (x_out_valid_d = '1') then
                write(my_line, string'(HT & HT & "x_out: destination = ("));
                write(my_line, to_integer(unsigned(x_out_d((COORD_BITS-1) downto 0))));
                write(my_line, string'(", "));
                write(my_line, to_integer(unsigned(x_out_d((2*COORD_BITS-1) downto COORD_BITS))));
                write(my_line, string'("), data = "));
                write(my_line, x_out_d((BUS_WIDTH-1) downto 2*COORD_BITS));
                write(my_line, string'(", raw = "));
                write(my_line, x_out_d((BUS_WIDTH-1) downto 0));
                
                writeline(output, my_line);
            end if;
            
            if (y_out_valid_d = '1') then
                write(my_line, string'(HT & HT & "y_out: destination = ("));
                write(my_line, to_integer(unsigned(y_out_d((COORD_BITS-1) downto 0))));
                write(my_line, string'(", "));
                write(my_line, to_integer(unsigned(y_out_d((2*COORD_BITS-1) downto COORD_BITS))));
                write(my_line, string'("), data = "));
                write(my_line, y_out_d((BUS_WIDTH-1) downto 2*COORD_BITS));
                write(my_line, string'(", raw = "));
                write(my_line, y_out_d((BUS_WIDTH-1) downto 0));
                
                writeline(output, my_line);
            end if;
        end if;
    end process PRINT;
    
    PE : hoplite_tb_pe
        generic map (
            BUS_WIDTH   => BUS_WIDTH,
            X_COORD     => X_COORD,
            Y_COORD     => Y_COORD,
            COORD_BITS  => COORD_BITS
        )
        port map (
            clk                 => clk,
            reset_n             => reset_n,
            count               => count,
            trig                => trig,
            x_dest              => x_dest,
            y_dest              => y_dest,
            message_out         => pe_message_out,
            message_out_valid   => pe_message_out_valid,
            message_in          => pe_message_in,
            message_in_valid    => pe_message_in_valid
        );

end Behavioral;
