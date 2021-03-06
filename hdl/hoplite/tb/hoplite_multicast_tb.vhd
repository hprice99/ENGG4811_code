library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.math_real.all;

use STD.textio.all;
use IEEE.std_logic_textio.all;

use std.env.finish;
use std.env.stop;

library xil_defaultlib;
use xil_defaultlib.hoplite_network_tb_defs.all;
use xil_defaultlib.multicast_defs.all;
use xil_defaultlib.math_functions.all;

entity hoplite_multicast_tb is
end hoplite_multicast_tb;

architecture Behavioral of hoplite_multicast_tb is

    component hoplite_multicast_tb_node
    Generic (
        BUS_WIDTH               : integer := 32;
        X_COORD                 : integer := 0;
        Y_COORD                 : integer := 0;
        COORD_BITS              : integer := 1;
        
        MULTICAST_COORD_BITS    : integer := 1;
        MULTICAST_X_COORD       : integer := 1;
        MULTICAST_Y_COORD       : integer := 1;
        USE_MULTICAST           : boolean := False
    );
    Port ( 
        clk                 : in std_logic;
        reset_n             : in std_logic;
        count               : in INTEGER;
        
        x_dest              : in std_logic_vector((COORD_BITS-1) downto 0);
        y_dest              : in std_logic_vector((COORD_BITS-1) downto 0);
        trig                : in std_logic;
        trig_broadcast      : in std_logic;
        
        -- Input (messages received by node)
        x_in                : in std_logic_vector((BUS_WIDTH-1) downto 0);
        x_in_valid          : in std_logic;
        
        y_in                : in std_logic_vector((BUS_WIDTH-1) downto 0);
        y_in_valid          : in std_logic;
        
        multicast_in        : in std_logic_vector((BUS_WIDTH-1) downto 0);
        multicast_in_valid  : in std_logic;
        
        -- Output (messages sent by node)
        x_out               : out std_logic_vector((BUS_WIDTH-1) downto 0);
        x_out_valid         : out std_logic;
        
        y_out               : out std_logic_vector((BUS_WIDTH-1) downto 0);
        y_out_valid         : out std_logic;
        
        multicast_out           : out std_logic_vector((BUS_WIDTH-1) downto 0);
        multicast_out_valid     : out std_logic;
        multicast_backpressure  : in std_logic;
        
        -- Message checking signals
        last_message_sent       : out std_logic_vector ((BUS_WIDTH-1) downto 0);
        message_sent            : out std_logic;
        
        last_message_received   : out std_logic_vector ((BUS_WIDTH-1) downto 0);
        message_received        : out std_logic
    );
    end component hoplite_multicast_tb_node;
    
    component multicast_router_node is
    Generic (
        BUS_WIDTH               : integer := 32;
        COORD_BITS              : integer := 1;

        MULTICAST_COORD_BITS    : integer := 1;
        MULTICAST_X_COORD       : integer := 1;
        MULTICAST_Y_COORD       : integer := 1;

        FIFO_DEPTH              : integer := 32
    );
    Port ( 
        clk             : in std_logic;
        reset_n         : in std_logic;
        
        -- Input
        x_in                    : in std_logic_vector((BUS_WIDTH-1) downto 0);
        x_in_valid              : in std_logic;
        y_in                    : in std_logic_vector((BUS_WIDTH-1) downto 0);
        y_in_valid              : in std_logic;
        multicast_in            : in t_NodeToMulticastPackets;
        multicast_in_valid      : in t_NodeToMulticastPacketsValid;
        multicast_available     : out t_NodeToMulticastPacketsValid;
        
        -- Output
        x_out                   : out std_logic_vector((BUS_WIDTH-1) downto 0);
        x_out_valid             : out std_logic;
        y_out                   : out std_logic_vector((BUS_WIDTH-1) downto 0);
        y_out_valid             : out std_logic;
        multicast_out           : out std_logic_vector((BUS_WIDTH-1) downto 0);
        multicast_out_valid     : out std_logic
    );
    end component multicast_router_node;
    
    component fifo_sync
        generic (
            BUS_WIDTH   : integer := 32;
            FIFO_DEPTH  : integer := 64
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
    end component fifo_sync;
    
    signal clk          : std_logic := '0';
    constant clk_period : time := 10 ns;
    
    signal reset_n      : std_logic;
    
    signal count            : integer;
    
    constant USE_MULTICAST          : boolean := True;
    constant MULTICAST_FIFO_DEPTH   : integer := MAX_MESSAGE_COUNT;
    
    type t_Counts is array (0 to (NETWORK_COLS-1), 0 to (NETWORK_ROWS-1)) of integer;
    type t_MessageCounts is array (0 to (NETWORK_COLS-1), 0 to (NETWORK_ROWS-1)) of t_Counts;
    signal row_broadcasts_sent, column_messages_sent            : t_MessageCounts;
    signal row_broadcasts_received, column_messages_received    : t_MessageCounts;
    
    signal expected_row_broadcasts_received, expected_column_messages_received    : t_MessageCounts;
    
    -- Array of message interfaces between nodes
    signal destinations : t_Destination;
    signal x_messages_out, y_messages_out, multicast_messages_out : t_Message;
    signal x_messages_out_valid, y_messages_out_valid, multicast_messages_out_valid : t_MessageValid;
    signal x_messages_in, y_messages_in, multicast_messages_in : t_Message;
    signal x_messages_in_valid, y_messages_in_valid, multicast_messages_in_valid : t_MessageValid;
    signal trig : t_Trigger;
    signal trig_broadcast : t_Trigger;
    
    signal multicast_backpressure   : t_MessageValid;
    
    signal multicast_x_messages_out, multicast_y_messages_out   : t_MulticastToMulticastPackets;
    signal multicast_x_messages_out_valid, multicast_y_messages_out_valid   : t_MulticastToMulticastPacketsValid;
    
    signal multicast_to_node_messages_out       : t_MulticastToNodePackets;
    signal multicast_to_node_messages_out_valid : t_MulticastToNodePacketsValid;
    
    signal multicast_x_messages_in, multicast_y_messages_in     : t_MulticastToMulticastPackets;
    signal multicast_x_messages_in_valid, multicast_y_messages_in_valid   : t_MulticastToMulticastPacketsValid;
    
    signal node_to_multicast_messages_in        : t_CombinedNodeToMulticastPackets;
    signal node_to_multicast_messages_in_valid  : t_CombinedNodeToMulticastPacketValid;
    signal node_to_multicast_available          : t_CombinedNodeToMulticastPacketValid;
    
    constant TEST_SRC_ROW           : integer := 0;
    constant TEST_BROADCAST_COL     : integer := 0;

    -- Message checking FIFO   
    constant FIFO_DEPTH     : integer := MAX_MESSAGE_COUNT;
    
    -- Messages to send into checking FIFOs
    signal expected_messages_sent        : t_FifoMessage;
    signal expected_messages_sent_valid  : t_FifoMessageValid;
    
    signal expected_messages_received       : t_FifoMessage;
    signal expected_messages_received_valid : t_FifoMessageValid;
    
    -- Messages sent by processing elements
    signal last_messages_sent               : t_Message;
    signal last_messages_sent_destination   : t_Destination;
    signal messages_sent                    : t_MessageValid;
    signal last_messages_sent_multicast_destination   : t_MulticastDestination;

    -- Messages received by processing elements
    signal last_messages_received       : t_Message;
    signal last_messages_received_src   : t_Destination;
    signal messages_received            : t_MessageValid;
    signal last_messages_received_multicast_destination   : t_MulticastDestination;
    
begin
    
    assert ((USE_MULTICAST = true and MULTICAST_COORD_BITS > 0) or (USE_MULTICAST = False)) report "MULTICAST_COORD_BITS must be set when USE_MULTICAST is enabled" severity failure;

    -- Generate clk and reset_n
    reset_n <= '0', '1' after clk_period;
    
    CLK_PROCESS: process
    begin
        clk <= '0';
        wait for clk_period/2;
        clk <= '1';
        wait for clk_period/2;
    end process CLK_PROCESS;
    
    COUNTER: process(clk)
        variable my_line : line;
    begin
        if (rising_edge(clk)) then
            if (reset_n = '0') then
                count   <= 0;
            else
                count   <= count + 1;
                
                write(my_line, string'(CR & LF & "Cycle "));
                write(my_line, count);
                writeline(output, my_line);
                
                if (count = MAX_COUNT) then
                    stop;
                end if;
            end if;
        end if;
    end process COUNTER;

    -- Generate the network
    NETWORK_ROW_GEN: for i in 0 to (NETWORK_ROWS-1) generate
        constant prev_multicast_x   : integer := 1;
        constant prev_multicast_y   : integer := ((i-1) mod NETWORK_ROWS) + 1;
        constant curr_multicast_x   : integer := 1;
        constant curr_multicast_y   : integer := i+1;
        constant next_multicast_x   : integer := 1;
        constant next_multicast_y   : integer := ((i+1) mod NETWORK_ROWS) + 1;
    begin
        MULTICAST_ROUTER_GEN: if (USE_MULTICAST = true) generate
            MULTICAST_ROUTER: multicast_router_node
                generic map (
                    BUS_WIDTH               => BUS_WIDTH,
                    COORD_BITS              => COORD_BITS,
            
                    MULTICAST_COORD_BITS    => MULTICAST_COORD_BITS,
                    MULTICAST_X_COORD       => curr_multicast_x,
                    MULTICAST_Y_COORD       => curr_multicast_y,
            
                    FIFO_DEPTH              => MULTICAST_FIFO_DEPTH
                )
                port map ( 
                    clk             => clk,
                    reset_n         => reset_n,
                    
                    -- Input
                    x_in                    => multicast_x_messages_in(curr_multicast_x, curr_multicast_y),
                    x_in_valid              => multicast_x_messages_in_valid(curr_multicast_x, curr_multicast_y),
                    y_in                    => multicast_y_messages_in(curr_multicast_x, curr_multicast_y),
                    y_in_valid              => multicast_y_messages_in_valid(curr_multicast_x, curr_multicast_y),
                    multicast_in            => node_to_multicast_messages_in(curr_multicast_x, curr_multicast_y),
                    multicast_in_valid      => node_to_multicast_messages_in_valid(curr_multicast_x, curr_multicast_y),
                    multicast_available     => node_to_multicast_available(curr_multicast_x, curr_multicast_y),
                    
                    -- Output
                    x_out                   => multicast_x_messages_out(curr_multicast_x, curr_multicast_y),
                    x_out_valid             => multicast_x_messages_out_valid(curr_multicast_x, curr_multicast_y),
                    y_out                   => multicast_y_messages_out(curr_multicast_x, curr_multicast_y),
                    y_out_valid             => multicast_y_messages_out_valid(curr_multicast_x, curr_multicast_y),
                    multicast_out           => multicast_to_node_messages_out(curr_multicast_x, curr_multicast_y),
                    multicast_out_valid     => multicast_to_node_messages_out_valid(curr_multicast_x, curr_multicast_y)
                );
                
                multicast_x_messages_in(curr_multicast_x, curr_multicast_y)       <= (others => '0');
                multicast_x_messages_in_valid(curr_multicast_x, curr_multicast_y) <= '0';

                multicast_y_messages_in(curr_multicast_x, curr_multicast_y)       <= multicast_y_messages_out(curr_multicast_x, prev_multicast_y);
                multicast_y_messages_in_valid(curr_multicast_x, curr_multicast_y) <= multicast_y_messages_out_valid(curr_multicast_x, prev_multicast_y);
            end generate MULTICAST_ROUTER_GEN;

        NETWORK_COL_GEN: for j in 0 to (NETWORK_COLS-1) generate
            constant prev_y         : integer := ((i-1) mod NETWORK_ROWS);
            constant prev_x         : integer := ((j-1) mod NETWORK_COLS);
            constant curr_y         : integer := i;
            constant curr_x         : integer := j;
            constant next_y         : integer := ((i+1) mod NETWORK_ROWS);
            constant next_x         : integer := ((j+1) mod NETWORK_COLS);
            constant multicast_cluster_node_number  : integer := curr_x;
        begin
            -- Assign multicast packets
            USE_MULTICAST_PACKET_ASSIGN: if (USE_MULTICAST = True) generate
            begin
                -- Messages from multicast layer to node
                multicast_messages_in(curr_x, curr_y)       <= multicast_to_node_messages_out(curr_multicast_x, curr_multicast_y);
                multicast_messages_in_valid(curr_x, curr_y) <= multicast_to_node_messages_out_valid(curr_multicast_x, curr_multicast_y);
                
                -- Messages from node to multicast layer
                multicast_backpressure(curr_x, curr_y)  <= not node_to_multicast_available(curr_multicast_x, curr_multicast_y)(multicast_cluster_node_number);
                node_to_multicast_messages_in(curr_multicast_x, curr_multicast_y)(multicast_cluster_node_number)         <= multicast_messages_out(curr_x, curr_y);
                node_to_multicast_messages_in_valid(curr_multicast_x, curr_multicast_y)(multicast_cluster_node_number)   <= multicast_messages_out_valid(curr_x, curr_y);
            end generate USE_MULTICAST_PACKET_ASSIGN;
            
            NOT_USE_MULTICAST_PACKET_ASSIGN: if (USE_MULTICAST = False) generate
            begin
                -- Messages from multicast layer to node
                multicast_messages_in(curr_x, curr_y)       <= (others => '0');
                multicast_messages_in_valid(curr_x, curr_y) <= '0';
                
                -- Messages from node to multicast layer
                multicast_backpressure(curr_x, curr_y)  <= '0';
                node_to_multicast_messages_in(curr_multicast_x, curr_multicast_y)(multicast_cluster_node_number)         <= (others => '0');
                node_to_multicast_messages_in_valid(curr_multicast_x, curr_multicast_y)(multicast_cluster_node_number)   <= '0';
            end generate NOT_USE_MULTICAST_PACKET_ASSIGN;
        
            -- Instantiate node
            NODE: hoplite_multicast_tb_node
            generic map (
                BUS_WIDTH               => BUS_WIDTH,
                X_COORD                 => curr_x,
                Y_COORD                 => curr_y,
                COORD_BITS              => COORD_BITS,
                
                MULTICAST_COORD_BITS    => MULTICAST_COORD_BITS,
                MULTICAST_X_COORD       => curr_multicast_x,
                MULTICAST_Y_COORD       => curr_multicast_y,
                USE_MULTICAST           => USE_MULTICAST
            )
            port map (
                clk                 => clk,
                reset_n             => reset_n,
                
                count               => count,
                trig                => trig(curr_x, curr_y),
                trig_broadcast      => trig_broadcast(curr_x, curr_y),
                
                -- Signals to create outgoing messages
                x_dest              => destinations(curr_x, curr_y)(X_INDEX),
                y_dest              => destinations(curr_x, curr_y)(Y_INDEX),
                
                -- Messages incoming to router
                x_in                    => x_messages_in(curr_x, curr_y),
                x_in_valid              => x_messages_in_valid(curr_x, curr_y),
                y_in                    => y_messages_in(curr_x, curr_y),
                y_in_valid              => y_messages_in_valid(curr_x, curr_y),
                multicast_in            => multicast_messages_in(curr_x, curr_y),
                multicast_in_valid      => multicast_messages_in_valid(curr_x, curr_y),
                
                -- Messages outgoing from router
                x_out                   => x_messages_out(curr_x, curr_y),
                x_out_valid             => x_messages_out_valid(curr_x, curr_y),
                y_out                   => y_messages_out(curr_x, curr_y),
                y_out_valid             => y_messages_out_valid(curr_x, curr_y),
                multicast_out           => multicast_messages_out(curr_x, curr_y),
                multicast_out_valid     => multicast_messages_out_valid(curr_x, curr_y),
                multicast_backpressure  => multicast_backpressure(curr_x, curr_y),
                
                -- Messages sent by the contained processing element
                last_message_sent   => last_messages_sent(curr_x, curr_y),
                message_sent        => messages_sent(curr_x, curr_y),
                
                -- Messages received by the contained processing element
                last_message_received   => last_messages_received(curr_x, curr_y),
                message_received        => messages_received(curr_x, curr_y)
            );
            
            -- Connect in and out messages
            x_messages_in(curr_x, curr_y)       <= x_messages_out(prev_x, curr_y);
            x_messages_in_valid(curr_x, curr_y) <= x_messages_out_valid(prev_x, curr_y);
            
            y_messages_in(curr_x, curr_y)       <= y_messages_out(curr_x, prev_y);
            y_messages_in_valid(curr_x, curr_y) <= y_messages_out_valid(curr_x, prev_y);
            
            -- Set destination
            SET_DESTINATION: process (clk)
            begin
                if (rising_edge(clk) and reset_n = '1') then
                    if (row_broadcasts_sent(curr_x, curr_y)(next_x, curr_y) < MESSAGE_BURST) then
                        destinations(curr_x, curr_y)(X_INDEX) <= std_logic_vector(to_unsigned(next_x, COORD_BITS));            
                        destinations(curr_x, curr_y)(Y_INDEX) <= std_logic_vector(to_unsigned(curr_y, COORD_BITS));
                    elsif (column_messages_sent(curr_x, curr_y)(curr_x, next_y) < MESSAGE_BURST) then
                        destinations(curr_x, curr_y)(X_INDEX) <= std_logic_vector(to_unsigned(curr_x, COORD_BITS));            
                        destinations(curr_x, curr_y)(Y_INDEX) <= std_logic_vector(to_unsigned(next_y, COORD_BITS));
                    else
                        destinations(curr_x, curr_y)(X_INDEX) <= std_logic_vector(to_unsigned(next_x, COORD_BITS));            
                        destinations(curr_x, curr_y)(Y_INDEX) <= std_logic_vector(to_unsigned(next_y, COORD_BITS));
                    end if;
                end if;
            end process SET_DESTINATION;

            TRIG_FF: process (clk)
            begin
                if (rising_edge(clk)) then
                    trig(curr_x, curr_y)            <= '0';
                    trig_broadcast(curr_x, curr_y)  <= '0';
                
                    if (reset_n = '0') then
                        trig(curr_x, curr_y)            <= '0';
                        trig_broadcast(curr_x, curr_y)  <= '0';
                        
                        for dest_y in 0 to (NETWORK_ROWS-1) loop
                            for dest_x in 0 to (NETWORK_COLS-1) loop
                                -- Set broadcast count on diagonals to 0, and MESSAGE_BURST otherwise
                                if (curr_x = curr_y) then
                                    row_broadcasts_sent(curr_x, curr_y)(dest_x, dest_y)     <= 0;
                                else
                                    row_broadcasts_sent(curr_x, curr_y)(dest_x, dest_y)     <= MESSAGE_BURST;
                                end if;
                                column_messages_sent(curr_x, curr_y)(dest_x, dest_y)    <= 0;
                            end loop;
                        end loop;
                        
                    -- Broadcast from diagonal elements
                    elsif (row_broadcasts_sent(curr_x, curr_y)(next_x, curr_y) < MESSAGE_BURST
                            and curr_y = curr_x) then
                        trig(curr_x, curr_y)                                    <= '1';
                        trig_broadcast(curr_x, curr_y)                          <= '1';
                        row_broadcasts_sent(curr_x, curr_y)(next_x, curr_y) <= row_broadcasts_sent(curr_x, curr_y)(next_x, curr_y) + 1;
                    
                    -- Send messages down each column
                    elsif (row_broadcasts_received(0, 0)(1, 0) = MESSAGE_BURST
                            and column_messages_sent(curr_x, curr_y)(curr_x, next_y) < MESSAGE_BURST
                            and curr_y = TEST_SRC_ROW) then
                        trig(curr_x, curr_y)                                        <= '1';
                        trig_broadcast(curr_x, curr_y)                              <= '0';
                        column_messages_sent(curr_x, curr_y)(curr_x, next_y)    <= column_messages_sent(curr_x, curr_y)(curr_x, next_y) + 1;
                    
                    else
                        trig(curr_x, curr_y)            <= '0';
                        trig_broadcast(curr_x, curr_y)  <= '0';
                    end if;
                end if;
            end process TRIG_FF;
        end generate NETWORK_COL_GEN;
    end generate NETWORK_ROW_GEN;
    
    -- Configure signals for message checking FIFO
    FIFO_SRC_ROW_CONTROL: for src_y in 0 to (NETWORK_ROWS-1) generate
        FIFO_SRC_COL_CONTROL: for src_x in 0 to (NETWORK_COLS-1) generate
        begin
            last_messages_sent_destination(src_x, src_y)    <= get_dest_coord(last_messages_sent(src_x, src_y));
            last_messages_sent_multicast_destination(src_x, src_y)  <= get_multicast_coord(last_messages_sent(src_x, src_y));
            
            FIFO_DEST_ROW_CONTROL: for dest_y in 0 to (NETWORK_ROWS-1) generate
                FIFO_DEST_COL_CONTROL: for dest_x in 0 to (NETWORK_COLS-1) generate
                    constant src_y_signal : std_logic_vector((COORD_BITS-1) downto 0) := std_logic_vector(to_unsigned(src_y, COORD_BITS));
                    constant src_x_signal : std_logic_vector((COORD_BITS-1) downto 0) := std_logic_vector(to_unsigned(src_x, COORD_BITS));
                    constant dest_y_signal : std_logic_vector((COORD_BITS-1) downto 0) := std_logic_vector(to_unsigned(dest_y, COORD_BITS));
                    constant dest_x_signal : std_logic_vector((COORD_BITS-1) downto 0) := std_logic_vector(to_unsigned(dest_x, COORD_BITS));
                    constant multicast_x_signal : std_logic_vector((MULTICAST_COORD_BITS-1) downto 0) := std_logic_vector(to_unsigned(1, MULTICAST_COORD_BITS));
                    constant multicast_y_signal : std_logic_vector((MULTICAST_COORD_BITS-1) downto 0) := std_logic_vector(to_unsigned(src_y+1, MULTICAST_COORD_BITS));
                begin
                    last_messages_received_src(dest_x, dest_y)  <= get_source_coord(last_messages_received(dest_x, dest_y));
                    last_messages_received_multicast_destination(dest_x, dest_y) <= get_multicast_coord(last_messages_received(dest_x, dest_y));
                
                    -- FIFO for checking messages are correctly routed
                    CHECK_FIFO: fifo_sync
                    generic map (
                        BUS_WIDTH   => BUS_WIDTH,
                        FIFO_DEPTH  => FIFO_DEPTH
                    )
                    port map (
                        clk         => clk,
                        reset_n     => reset_n,
                        
                        write_en    => expected_messages_sent_valid(src_x, src_y)(dest_x, dest_y),
                        write_data  => expected_messages_sent(src_x, src_y)(dest_x, dest_y),
                        
                        read_en     => expected_messages_received_valid(src_x, src_y)(dest_x, dest_y),
                        read_data   => expected_messages_received(src_x, src_y)(dest_x, dest_y),
                        
                        full        => open,
                        empty       => open
                    );
                    
                    -- Assign messages sent to the correct FIFO                   
                    ASSIGN_MESSAGE_SENT: process(clk)
                    begin
                        if (rising_edge(clk) and reset_n = '1') then
                            if (messages_sent(src_x, src_y) = '1' 
                                    and ((last_messages_sent_destination(src_x, src_y)(X_INDEX) = dest_x_signal
                                    and last_messages_sent_destination(src_x, src_y)(Y_INDEX) = dest_y_signal)
                                    or (USE_MULTICAST = true and src_y = dest_y and last_messages_sent_multicast_destination(src_x, src_y)(X_INDEX) = multicast_x_signal
                                    and last_messages_sent_multicast_destination(src_x, src_y)(Y_INDEX) = multicast_y_signal))) then
                                expected_messages_sent_valid(src_x, src_y)(dest_x, dest_y)  <= '1';
                                expected_messages_sent(src_x, src_y)(dest_x, dest_y)        <= last_messages_sent(src_x, src_y);
                            else
                                expected_messages_sent_valid(src_x, src_y)(dest_x, dest_y)  <= '0';
                                expected_messages_sent(src_x, src_y)(dest_x, dest_y)        <= (others => '0');
                            end if;
                        end if;
                    end process ASSIGN_MESSAGE_SENT;
                    
                    -- Assign messages received to the correct FIFO
                    ASSIGN_MESSAGE_RECEIVED: process(clk)
                    begin
                        if (rising_edge(clk) and reset_n = '1') then
                            if (messages_received(dest_x, dest_y) = '1' 
                                    and ((last_messages_received_src(dest_x, dest_y)(X_INDEX) = src_x_signal
                                    and last_messages_received_src(dest_x, dest_y)(Y_INDEX) = src_y_signal))
                                    ) then
                                expected_messages_received_valid(src_x, src_y)(dest_x, dest_y)  <= '1';
                            else
                                expected_messages_received_valid(src_x, src_y)(dest_x, dest_y)  <= '0';
                            end if;
                        end if;
                    end process ASSIGN_MESSAGE_RECEIVED;
                    
                    -- Check message received
                    CHECK_MESSAGE_RECEIVED: process(clk)
                        variable my_line : line;
                    begin
                        if (rising_edge(clk)) then
                            if (reset_n = '0') then 
                                row_broadcasts_received(src_x, src_y)(dest_x, dest_y)   <= 0;
                                column_messages_received(src_x, src_y)(dest_x, dest_y)  <= 0;
                            elsif (messages_received(dest_x, dest_y) = '1') then
                                if (expected_messages_received(src_x, src_y)(dest_x, dest_y) = last_messages_received(dest_x, dest_y)) then
                                    write(my_line, string'(HT & "hoplite_unicast_tb: "));
        
                                    write(my_line, string'("Node ("));
                                    write(my_line, dest_x);
                                    
                                    write(my_line, string'(", "));
                                    write(my_line, dest_y);
                                    write(my_line, string'(")"));
                                    
                                    write(my_line, string'(" received message successfully"));
                                    
                                    writeline(output, my_line);

                                    if (last_messages_received(dest_x, dest_y)(BUS_WIDTH-1) = '1') then
                                        row_broadcasts_received(src_x, src_y)(dest_x, dest_y)   <= row_broadcasts_received(src_x, src_y)(dest_x, dest_y) + 1;
                                    else
                                        column_messages_received(src_x, src_y)(dest_x, dest_y)  <= column_messages_received(src_x, src_y)(dest_x, dest_y) + 1;
                                    end if;
                                
                                    my_line := print_packet(string'("last_messages_received"), last_messages_received(dest_x, dest_y));
                                
                                    writeline(output, my_line);
                                elsif (last_messages_received_src(dest_x, dest_y)(X_INDEX) = src_x_signal
                                            and last_messages_received_src(dest_x, dest_y)(Y_INDEX) = src_y_signal
                                            and expected_messages_received(src_x, src_y)(dest_x, dest_y) /= last_messages_received(dest_x, dest_y)) then
                                    write(my_line, string'(CR & LF & HT & "hoplite_unicast_tb: "));
        
                                    write(my_line, string'("Node ("));
                                    write(my_line, dest_x);
                                    
                                    write(my_line, string'(", "));
                                    write(my_line, dest_y);
                                    write(my_line, string'(")"));
                                    
                                    write(my_line, string'(" did not receive message successfully from node ("));
                                    write(my_line, src_x);
                                    
                                    write(my_line, string'(", "));
                                    write(my_line, src_y);
                                    write(my_line, string'(")"));
                                    
                                    writeline(output, my_line);
                                    
                                    my_line := print_packet(string'("last_messages_received"), last_messages_received(dest_x, dest_y));
                                    
                                    writeline(output, my_line);

                                    my_line := print_packet(string'("expected_messages_received"), expected_messages_received(src_x, src_y)(dest_x, dest_y));
                                    
                                    writeline(output, my_line);
                                    
                                    stop;
                                end if;
                            end if;
                        end if;
                    end process CHECK_MESSAGE_RECEIVED;
                    
                    -- Set the number of messages expected
                    SET_BROADCAST_EXPECTED: if (src_x = src_y) generate
                        -- Broadcast to all nodes in the same row
                        BROADCAST_EXPECTED: if ((USE_MULTICAST = False and src_x /= dest_x and src_y = dest_y) or
                                (USE_MULTICAST = True and src_y = dest_y)) generate
                            expected_row_broadcasts_received(src_x, src_y)(dest_x, dest_y)    <= MESSAGE_BURST;
                        end generate BROADCAST_EXPECTED;
                        
                        BROADCAST_NOT_EXPECTED: if ((USE_MULTICAST = false and (src_x = dest_x or src_y /= dest_y)) or 
                                (USE_MULTICAST = true and src_y /= dest_y)) generate
                            expected_row_broadcasts_received(src_x, src_y)(dest_x, dest_y)    <= 0;
                        end generate BROADCAST_NOT_EXPECTED;
                    end generate SET_BROADCAST_EXPECTED;
                    
                    SET_BROADCAST_NOT_EXPECTED: if (src_x /= src_y) generate
                        expected_row_broadcasts_received(src_x, src_y)(dest_x, dest_y)    <= 0;
                    end generate SET_BROADCAST_NOT_EXPECTED;
                    
                    SET_COLUMN_EXPECTED: if (src_y = TEST_SRC_ROW) generate
                        -- Pick all elements on the row
                        COLUMN_EXPECTED: if (src_x = dest_x and src_y /= dest_y) generate
                            expected_column_messages_received(src_x, src_y)(dest_x, dest_y)    <= MESSAGE_BURST;
                        end generate COLUMN_EXPECTED;
                        
                        COLUMN_NOT_EXPECTED: if (src_x /= dest_x or src_y = dest_y) generate
                            expected_column_messages_received(src_x, src_y)(dest_x, dest_y)    <= 0;
                        end generate COLUMN_NOT_EXPECTED;
                    end generate SET_COLUMN_EXPECTED;
                    
                    SET_COLUMN_NOT_EXPECTED: if (src_y /= TEST_SRC_ROW) generate
                        expected_column_messages_received(src_x, src_y)(dest_x, dest_y)    <= 0;
                    end generate SET_COLUMN_NOT_EXPECTED;

                    CHECK_BROADCAST_MESSAGE_RECEIVED_COUNTS: process (row_broadcasts_received(src_x, src_y)(dest_x, dest_y))
                        variable my_line : line;
                    begin
                        if (reset_n = '1') then
                            write(my_line, row_broadcasts_received(src_x, src_y)(dest_x, dest_y));
                            write(my_line, string'(" broadcast messages from node ("));
                            write(my_line, src_x);
                            write(my_line, string'(", "));
                            write(my_line, src_y);
                            write(my_line, string'(") to node ("));
                            write(my_line, dest_x);
                            write(my_line, string'(", "));
                            write(my_line, dest_y);
                            write(my_line, string'(") have been received. "));
                            write(my_line, string'("Expected: "));
                            write(my_line, expected_row_broadcasts_received(src_x, src_y)(dest_x, dest_y));
                            
                            writeline(output, my_line);
                        
                            if (row_broadcasts_received(src_x, src_y)(dest_x, dest_y) = expected_row_broadcasts_received(src_x, src_y)(dest_x, dest_y)) then
                                write(my_line, string'("All broadcast messages from node ("));
                                write(my_line, src_x);
                                write(my_line, string'(", "));
                                write(my_line, src_y);
                                write(my_line, string'(") to node ("));
                                write(my_line, dest_x);
                                write(my_line, string'(", "));
                                write(my_line, dest_y);
                                write(my_line, string'(") have been received. "));
                                        
                                writeline(output, my_line);
                            end if;
                        end if;
                    end process CHECK_BROADCAST_MESSAGE_RECEIVED_COUNTS;
                    
                    CHECK_COLUMN_MESSAGE_RECEIVED_COUNTS: process (row_broadcasts_received(src_x, src_y)(dest_x, dest_y), 
                            column_messages_received(src_x, src_y)(dest_x, dest_y))
                        variable my_line : line;
                    begin
                        if (reset_n = '1') then
                            write(my_line, column_messages_received(src_x, src_y)(dest_x, dest_y));
                            write(my_line, string'(" column messages from node ("));
                            write(my_line, src_x);
                            write(my_line, string'(", "));
                            write(my_line, src_y);
                            write(my_line, string'(") to node ("));
                            write(my_line, dest_x);
                            write(my_line, string'(", "));
                            write(my_line, dest_y);
                            write(my_line, string'(") have been received. "));
                            write(my_line, string'("Expected: "));
                            write(my_line, expected_column_messages_received(src_x, src_y)(dest_x, dest_y));
                            
                            writeline(output, my_line);
                            
                            if (column_messages_received(src_x, src_y)(dest_x, dest_y) = expected_column_messages_received(src_x, src_y)(dest_x, dest_y)) then
                                write(my_line, string'("All column messages from node ("));
                                write(my_line, src_x);
                                write(my_line, string'(", "));
                                write(my_line, src_y);
                                write(my_line, string'(") to node ("));
                                write(my_line, dest_x);
                                write(my_line, string'(", "));
                                write(my_line, dest_y);
                                write(my_line, string'(") have been received"));
                                        
                                writeline(output, my_line);
                            end if;
                        end if;
                    end process CHECK_COLUMN_MESSAGE_RECEIVED_COUNTS;
                end generate FIFO_DEST_COL_CONTROL;
            end generate FIFO_DEST_ROW_CONTROL;
        end generate FIFO_SRC_COL_CONTROL;
    end generate FIFO_SRC_ROW_CONTROL;

    VERIFY_MESSAGES_RECEIVED_COUNT: process(clk)
        variable my_line : line;
    begin
        if (rising_edge(clk)) then
            if (reset_n = '1' 
                    and row_broadcasts_received = expected_row_broadcasts_received
                    and column_messages_received = expected_column_messages_received) then
                write(my_line, string'(CR & LF & "SUCCESS - All expected messages received"));    
                writeline(output, my_line);
                
                stop;      
            end if;
        end if;
    end process VERIFY_MESSAGES_RECEIVED_COUNT;

end Behavioral;
