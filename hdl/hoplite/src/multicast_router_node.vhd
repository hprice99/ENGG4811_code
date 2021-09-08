----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 09/03/2021 04:02:02 PM
-- Design Name: 
-- Module Name: multicast_router_node - Behavioral
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

library xil_defaultlib;
use xil_defaultlib.multicast_defs.all;
use xil_defaultlib.math_functions.all;

-- TODO Change multicast_in and multicast_out to buffer and network_to_pe
entity multicast_router_node is
    Generic (
        BUS_WIDTH               : integer := 32;
        COORD_BITS              : integer := 1;

        MULTICAST_COORD_BITS    : integer := 1;
        MULTICAST_X_COORD       : integer := 1;
        MULTICAST_Y_COORD       : integer := 1;

        FIFO_DEPTH              : integer := 32
    );
    Port ( 
        clk             : in STD_LOGIC;
        reset_n         : in STD_LOGIC;
        
        -- Input
        x_in                    : in STD_LOGIC_VECTOR((BUS_WIDTH-1) downto 0);
        x_in_valid              : in STD_LOGIC;
        y_in                    : in STD_LOGIC_VECTOR((BUS_WIDTH-1) downto 0);
        y_in_valid              : in STD_LOGIC;
        multicast_in            : in t_MulticastGroupPackets;
        multicast_in_valid      : in t_MulticastGroupPacketsValid;
        multicast_available     : out t_MulticastGroupPacketsValid;
        
        -- Output
        x_out                   : out STD_LOGIC_VECTOR((BUS_WIDTH-1) downto 0);
        x_out_valid             : out STD_LOGIC;
        y_out                   : out STD_LOGIC_VECTOR((BUS_WIDTH-1) downto 0);
        y_out_valid             : out STD_LOGIC;
        multicast_out           : out STD_LOGIC_VECTOR((BUS_WIDTH-1) downto 0);
        multicast_out_valid     : out STD_LOGIC
    );
end multicast_router_node;

architecture Behavioral of multicast_router_node is
    
    component multicast_router
        Generic (
            BUS_WIDTH               : integer := 32;
            COORD_BITS              : integer := 1;
    
            MULTICAST_COORD_BITS    : integer := 1;
            MULTICAST_X_COORD       : integer := 1;
            MULTICAST_Y_COORD       : integer := 1
        );
        Port ( 
            clk             : in STD_LOGIC;
            reset_n         : in STD_LOGIC;
            
            -- Input
            x_in                    : in STD_LOGIC_VECTOR((BUS_WIDTH-1) downto 0);
            x_in_valid              : in STD_LOGIC;
            y_in                    : in STD_LOGIC_VECTOR((BUS_WIDTH-1) downto 0);
            y_in_valid              : in STD_LOGIC;
            multicast_in            : in STD_LOGIC_VECTOR((BUS_WIDTH-1) downto 0);
            multicast_in_valid      : in STD_LOGIC;

            -- Output
            x_out                   : out STD_LOGIC_VECTOR((BUS_WIDTH-1) downto 0);
            x_out_valid             : out STD_LOGIC;
            y_out                   : out STD_LOGIC_VECTOR((BUS_WIDTH-1) downto 0);
            y_out_valid             : out STD_LOGIC;
            multicast_out           : out STD_LOGIC_VECTOR((BUS_WIDTH-1) downto 0);
            multicast_out_valid     : out STD_LOGIC;
            multicast_backpressure  : out STD_LOGIC
        );
    end component multicast_router;

    component fifo_sync_wrapper
        generic (
            BUS_WIDTH   : integer := 32;
            FIFO_DEPTH  : integer := 64;
            
            USE_INITIALISATION_FILE : boolean := True;
            INITIALISATION_FILE     : string := "none";
            INITIALISATION_LENGTH   : integer := 0
        );
        port (
            clk         : in std_logic;
            reset_n     : in std_logic;
    
            write_en    : in std_logic;
            write_data  : in std_logic_vector((BUS_WIDTH-1) downto 0);
            
            read_en     : in std_logic;
            read_data   : out std_logic_vector((BUS_WIDTH-1) downto 0);
            
            full        : out std_logic;
            empty       : out std_logic
        );
    end component fifo_sync_wrapper;

    -- Select signal for multicast_in source
    signal source_select    : integer range 1 to MULTICAST_GROUP_NODES;

    -- multicast_in packet from selected source
    signal active_multicast_in          : std_logic_vector((BUS_WIDTH-1) downto 0);
    signal active_multicast_in_valid    : std_logic;

    -- Control whether the multicast_out port is free and buffered packets can be read out
    signal multicast_backpressure   : std_logic;
    signal multicast_ready          : std_logic;

    -- Buffer signals
    signal buffer_fifo_write_en     : t_MulticastGroupPacketsValid;
    signal buffer_fifo_write_data   : t_MulticastGroupPackets;
    
    signal buffer_fifo_read_en      : t_MulticastGroupPacketsValid;
    signal buffer_fifo_read_data    : t_MulticastGroupPackets;

    signal buffer_fifo_full         : t_MulticastGroupPacketsValid;
    signal buffer_fifo_empty        : t_MulticastGroupPacketsValid;
    
    function rotate_left (vect : in std_logic_vector) return std_logic_vector is
        variable rotated_vect   : std_logic_vector((vect'length-1) downto 0);
    begin
        rotated_vect    := vect((vect'length - 2) downto 0) & vect(vect'length - 1);
        
        return rotated_vect;
    end function rotate_left;

begin

    ROUTER: multicast_router
        generic map (
            BUS_WIDTH               => BUS_WIDTH,
            COORD_BITS              => COORD_BITS,
    
            MULTICAST_COORD_BITS    => MULTICAST_COORD_BITS,
            MULTICAST_X_COORD       => MULTICAST_X_COORD,
            MULTICAST_Y_COORD       => MULTICAST_Y_COORD
        )
        port map (
            clk         => clk,
            reset_n     => reset_n,

            -- Input
            x_in                    => x_in,
            x_in_valid              => x_in_valid,
            y_in                    => y_in,
            y_in_valid              => y_in_valid,
            multicast_in            => active_multicast_in,
            multicast_in_valid      => active_multicast_in_valid,

            -- Output
            x_out                   => x_out,
            x_out_valid             => x_out_valid,
            y_out                   => y_out, 
            y_out_valid             => y_out_valid,
            multicast_out           => multicast_out,
            multicast_out_valid     => multicast_out_valid,
            multicast_backpressure  => multicast_backpressure
        );

    multicast_ready <= not multicast_backpressure;

    -- Buffer and arbitrate active_multicast_in
    BUFFER_GEN: for i in 0 to (MULTICAST_GROUP_NODES-1) generate
    begin
        BUFFER_FIFO: fifo_sync_wrapper
            generic map (
                BUS_WIDTH   => BUS_WIDTH,
                FIFO_DEPTH  => FIFO_DEPTH,

                USE_INITIALISATION_FILE => False,
                INITIALISATION_FILE     => "none",
                INITIALISATION_LENGTH   => 0
            )
            port map (
                clk         => clk,
                reset_n     => reset_n,
                
                write_en    => buffer_fifo_write_en(i),
                write_data  => buffer_fifo_write_data(i),
                
                read_en     => buffer_fifo_read_en(i),
                read_data   => buffer_fifo_read_data(i),
                
                full        => buffer_fifo_full(i),
                empty       => buffer_fifo_empty(i)
            );
        
        -- Writing to buffer
        BUFFER_WRITE: process (clk)
        begin
            if (rising_edge(clk)) then
                if (reset_n = '0') then
                    buffer_fifo_write_data(i)   <= (others => '0');
                    buffer_fifo_write_en(i)     <= '0';
                elsif (buffer_fifo_full(i) = '0') then
                    if (multicast_in_valid(i) = '1') then
                        buffer_fifo_write_data(i)     <= multicast_in(i);
                        buffer_fifo_write_en(i)       <= '1';
                    else
                        buffer_fifo_write_en(i)       <= '0';
                    end if;
                end if;
            end if;
        end process BUFFER_WRITE;

        -- Read from buffer
        BUFFER_READ_ENABLE: process (buffer_fifo_empty(i), multicast_ready, source_select)
        begin
            if (buffer_fifo_empty(i) = '0' and source_select = i + 1) then
                buffer_fifo_read_en(i)   <= multicast_ready;
            else
                buffer_fifo_read_en(i)   <= '0';
            end if;
        end process BUFFER_READ_ENABLE;

        multicast_available(i)  <= not buffer_fifo_full(i);
    end generate BUFFER_GEN;

    -- Round-robin arbitration for reading from buffer
    ARBITRATOR: process (clk)
    begin
        if (rising_edge(clk)) then
            if (reset_n = '0') then
                -- Set first source as active
                source_select       <= 1;
            else
                -- Rotate through sources
                if (source_select = MULTICAST_GROUP_NODES) then
                    source_select <= 1;
                else
                    source_select <= source_select + 1;
                end if;
            end if;
        end if;
    end process ARBITRATOR;
    
    -- Select active multicast buffer data
--    ACTIVE_SELECT: process (source_select, multicast_ready, buffer_fifo_empty)
--    begin
--        active_multicast_in         <= buffer_fifo_read_data(source_select-1);
--        active_multicast_in_valid   <= multicast_ready and not buffer_fifo_empty(source_select-1);
--    end process ACTIVE_SELECT;

    ACTIVE_SELECT: process (source_select, buffer_fifo_read_en)
    begin
        active_multicast_in         <= buffer_fifo_read_data(source_select-1);
        active_multicast_in_valid   <= buffer_fifo_read_en(source_select-1);
    end process ACTIVE_SELECT;

end Behavioral;
