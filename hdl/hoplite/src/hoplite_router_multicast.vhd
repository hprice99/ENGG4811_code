library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity hoplite_router_multicast is
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
        clk             : in STD_LOGIC;
        reset_n         : in STD_LOGIC;
        
        -- Input (messages received by router)
        x_in            : in STD_LOGIC_VECTOR((BUS_WIDTH-1) downto 0);
        x_in_valid      : in STD_LOGIC;
        
        y_in            : in STD_LOGIC_VECTOR((BUS_WIDTH-1) downto 0);
        y_in_valid      : in STD_LOGIC;
        
        pe_in           : in STD_LOGIC_VECTOR((BUS_WIDTH-1) downto 0);
        pe_in_valid     : in STD_LOGIC;
        pe_backpressure : out STD_LOGIC;
        
        multicast_in            : in STD_LOGIC_VECTOR((BUS_WIDTH-1) downto 0);
        multicast_in_valid      : in STD_LOGIC;
        
        -- Output (messages sent out of router)
        x_out           : out STD_LOGIC_VECTOR((BUS_WIDTH-1) downto 0);
        x_out_valid     : out STD_LOGIC;
        
        y_out           : out STD_LOGIC_VECTOR((BUS_WIDTH-1) downto 0);
        y_out_valid     : out STD_LOGIC;
        
        pe_out          : out STD_LOGIC_VECTOR((BUS_WIDTH-1) downto 0);
        pe_out_valid    : out STD_LOGIC;
        
        multicast_out           : out STD_LOGIC_VECTOR((BUS_WIDTH-1) downto 0);
        multicast_out_valid     : out STD_LOGIC;
        multicast_backpressure  : in STD_LOGIC
    );
end hoplite_router_multicast;

architecture Behavioral of hoplite_router_multicast is
    
    signal x_d, x_q : std_logic_vector((BUS_WIDTH-1) downto 0);
    signal y_d, y_q : std_logic_vector((BUS_WIDTH-1) downto 0);
    signal pe_d : std_logic_vector((BUS_WIDTH-1) downto 0);
    signal multicast_in_d, multicast_in_q : std_logic_vector((BUS_WIDTH-1) downto 0);
    
    signal sel : std_logic_vector(1 downto 0);
    signal x_next, y_next : std_logic;
    
    signal x_in_valid_d : std_logic;
    signal y_in_valid_d : std_logic;
    signal pe_in_valid_d : std_logic;
    signal multicast_in_valid_d : std_logic;
    
    -- Received packet destinations
    type t_Coordinate is array (0 to 1) of std_logic_vector((COORD_BITS-1) downto 0);
    constant X_INDEX    : integer := 0;
    constant Y_INDEX    : integer := 1;
    signal x_in_dest_d, x_in_dest_q : t_Coordinate;
    signal y_in_dest_d, y_in_dest_q : t_Coordinate;
    signal pe_in_dest_d, pe_in_dest_q : t_Coordinate;
    
    constant X_INDEX_HEADER_START   : integer := 0;
    constant X_INDEX_HEADER_END     : integer := X_INDEX_HEADER_START + COORD_BITS - 1;
    
    constant Y_INDEX_HEADER_START   : integer := X_INDEX_HEADER_END + 1;
    constant Y_INDEX_HEADER_END     : integer := Y_INDEX_HEADER_START + COORD_BITS - 1;
    
    -- Received packet multicast coordinates
    constant MULTICAST_X_INDEX_HEADER_START  : integer := Y_INDEX_HEADER_END + 1;
    constant MULTICAST_X_INDEX_HEADER_END    : integer := MULTICAST_X_INDEX_HEADER_START + MULTICAST_COORD_BITS - 1;
    
    constant MULTICAST_Y_INDEX_HEADER_START  : integer := MULTICAST_X_INDEX_HEADER_END + 1;
    constant MULTICAST_Y_INDEX_HEADER_END    : integer := MULTICAST_Y_INDEX_HEADER_START + MULTICAST_COORD_BITS - 1;
    
    subtype t_MulticastCoord is std_logic_vector((MULTICAST_COORD_BITS-1) downto 0);
    type t_MulticastCoords is array (0 to 1) of t_MulticastCoord;
    
    signal x_in_multicast_coord_d, x_in_multicast_coord_q   : t_MulticastCoords;
    signal y_in_multicast_coord_d, y_in_multicast_coord_q   : t_MulticastCoords;
    signal pe_in_multicast_coord_d, pe_in_multicast_coord_q : t_MulticastCoords;
    signal multicast_in_multicast_coord_d, multicast_in_multicast_coord_q   : t_MulticastCoords;
    
    -- Determine if the packet received is destined for this node
    impure function is_valid_packet_in (packet_in_coord : in t_Coordinate; 
                                        packet_in_valid : in std_logic) 
                                        return boolean is
        variable is_valid   : boolean;  
    begin
        if (packet_in_valid = '1'
                and to_integer(unsigned(packet_in_coord(X_INDEX))) = X_COORD 
                and to_integer(unsigned(packet_in_coord(Y_INDEX))) = Y_COORD) then
            is_valid    := True;   
        else
            is_valid    := False; 
        end if;
        
        return is_valid;
    end function is_valid_packet_in;
    
    -- Determine if the packet received is a multicast packet destined for this node
    impure function is_valid_multicast_in (packet_in_multicast_coord : in t_MulticastCoords; 
                                           packet_in_valid : in std_logic) 
                                        return boolean is
        variable is_multicast   : boolean;  
    begin
        if (USE_MULTICAST = True
                and packet_in_valid = '1'
                and to_integer(unsigned(packet_in_multicast_coord(X_INDEX))) = MULTICAST_X_COORD 
                and to_integer(unsigned(packet_in_multicast_coord(Y_INDEX))) = MULTICAST_Y_COORD) then
            is_multicast    := True;   
        else
            is_multicast    := False; 
        end if;
        
        return is_multicast;
    end function is_valid_multicast_in;
    
    -- Determine if the packet sent must be sent out as a multicast packet
    impure function is_valid_multicast_out (packet_out_multicast_coord : in t_MulticastCoords; 
                                            packet_out_valid : in std_logic) 
                                            return boolean is
        variable is_multicast   : boolean;  
    begin
        if (USE_MULTICAST = True
                and packet_out_valid = '1'
                and to_integer(unsigned(packet_out_multicast_coord(X_INDEX))) /= 0 
                and to_integer(unsigned(packet_out_multicast_coord(Y_INDEX))) /= 0) then
            is_multicast    := True;   
        else
            is_multicast    := False; 
        end if;
        
        return is_multicast;
    end function is_valid_multicast_out;

begin

    -- If multicast is to be used, then MULTICAST_X_COORD and MULTICAST_Y_COORD must be positive
    assert ((USE_MULTICAST = True and MULTICAST_X_COORD > 0 and MULTICAST_Y_COORD > 0) or USE_MULTICAST = False) report "MULTICAST_COORDS must be set when USE_MULTICAST is enabled" severity failure;

    -- Assign destination coordinates   
    x_in_dest_d(X_INDEX) <= x_d(X_INDEX_HEADER_END downto X_INDEX_HEADER_START);
    x_in_dest_d(Y_INDEX) <= x_d(Y_INDEX_HEADER_END downto Y_INDEX_HEADER_START);
    
    y_in_dest_d(X_INDEX) <= y_d(X_INDEX_HEADER_END downto X_INDEX_HEADER_START);
    y_in_dest_d(Y_INDEX) <= y_d(Y_INDEX_HEADER_END downto Y_INDEX_HEADER_START);
    
    pe_in_dest_d(X_INDEX)   <= pe_d(X_INDEX_HEADER_END downto X_INDEX_HEADER_START);
    pe_in_dest_d(Y_INDEX)   <= pe_d(Y_INDEX_HEADER_END downto Y_INDEX_HEADER_START);
    
    -- Assign multicast coordinates
    x_in_multicast_coord_d(X_INDEX)  <= x_d(MULTICAST_X_INDEX_HEADER_END downto MULTICAST_X_INDEX_HEADER_START);
    x_in_multicast_coord_d(Y_INDEX)  <= x_d(MULTICAST_Y_INDEX_HEADER_END downto MULTICAST_Y_INDEX_HEADER_START);
    
    y_in_multicast_coord_d(X_INDEX)  <= y_d(MULTICAST_X_INDEX_HEADER_END downto MULTICAST_X_INDEX_HEADER_START);
    y_in_multicast_coord_d(Y_INDEX)  <= y_d(MULTICAST_Y_INDEX_HEADER_END downto MULTICAST_Y_INDEX_HEADER_START);
    
    pe_in_multicast_coord_d(X_INDEX)  <= pe_d(MULTICAST_X_INDEX_HEADER_END downto MULTICAST_X_INDEX_HEADER_START);
    pe_in_multicast_coord_d(Y_INDEX)  <= pe_d(MULTICAST_Y_INDEX_HEADER_END downto MULTICAST_Y_INDEX_HEADER_START);
    
    multicast_in_multicast_coord_d(X_INDEX)  <= multicast_in_d(MULTICAST_X_INDEX_HEADER_END downto MULTICAST_X_INDEX_HEADER_START);
    multicast_in_multicast_coord_d(Y_INDEX)  <= multicast_in_d(MULTICAST_Y_INDEX_HEADER_END downto MULTICAST_Y_INDEX_HEADER_START);
        
    x_in_valid_d <= x_in_valid;
    y_in_valid_d <= y_in_valid;
    pe_in_valid_d   <= pe_in_valid;
    multicast_in_valid_d    <= multicast_in_valid;

    -- Output routing
    sel <= y_in_valid & x_in_valid;
       
    -- Select X output 
    with sel select
        x_d <= pe_in    when "00",
               x_in     when "01",
               pe_in    when "10",
               x_in     when others;
               
    -- Select Y output 
    with sel select
        y_d <= pe_in    when "00",
               x_in     when "01",
               y_in     when "10",
               y_in     when others;
               
    pe_d    <= pe_in;
    multicast_in_d  <= multicast_in;
               
    -- Apply backpressure to the connected PE
    with sel select
        pe_backpressure <=  multicast_backpressure  when "00",
                            '1'                     when others;
    
    OUTPUT_FF : process (clk)
    begin
        if (rising_edge(clk)) then
            if (reset_n = '0') then
                x_q             <= (others => '0');
                y_q             <= (others => '0');
                multicast_in_q  <= (others => '0');
                
                pe_out          <= (others => '0');
                pe_out_valid    <= '0';
                
                multicast_out       <= (others => '0');
                multicast_out_valid <= '0';
            else
                x_q <= x_d;
                y_q <= y_d;
                multicast_in_q  <= multicast_in_d;
               
                -- pe_out
                -- Multicast packets can only be sent to the PE through multicast_in
                if (is_valid_multicast_in(multicast_in_multicast_coord_d, multicast_in_valid) = True) then
                    pe_out_valid    <= '1';
                    pe_out          <= multicast_in_d;
                
                elsif (is_valid_packet_in(pe_in_dest_d, pe_in_valid) = True
                        and is_valid_multicast_in(pe_in_multicast_coord_d, pe_in_valid) = False) then
                    pe_out_valid    <= '1';
                    pe_out          <= pe_d;
                
                elsif (is_valid_packet_in(x_in_dest_d, x_in_valid) = True
                        and is_valid_multicast_in(x_in_multicast_coord_d, x_in_valid) = False) then
                    pe_out_valid    <= '1'; 
                    pe_out          <= x_d;
                    
                elsif (is_valid_packet_in(y_in_dest_d, y_in_valid) = True
                        and is_valid_multicast_in(y_in_multicast_coord_d, y_in_valid) = False) then
                    pe_out_valid    <= '1';
                    pe_out          <= y_d;
                
                else
                    pe_out_valid    <= '0';
                    
                end if;
                
                -- multicast_out
                if (is_valid_multicast_out(pe_in_multicast_coord_d, pe_in_valid) = True) then
                    multicast_out_valid     <= '1'; 
                    multicast_out           <= pe_d;
                
                elsif (is_valid_multicast_out(x_in_multicast_coord_d, x_in_valid) = True) then
                    multicast_out_valid     <= '1'; 
                    multicast_out           <= x_d;
                    
                elsif (is_valid_multicast_out(y_in_multicast_coord_d, y_in_valid) = True) then
                    multicast_out_valid    <= '1';
                    multicast_out          <= y_d;
                
                else
                    multicast_out_valid    <= '0';
                    
                end if;
            end if;
        end if;
    end process OUTPUT_FF;
        
    -- Output to X and Y links
    x_out <= x_q;
    y_out <= y_q;

    NEXT_VALID: process (x_in_valid_d, x_in_dest_d, x_in_multicast_coord_d,
                            y_in_valid_d, y_in_dest_d, y_in_multicast_coord_d,
                            pe_in_valid_d, pe_in_dest_d, pe_in_multicast_coord_d,
                            multicast_in_valid_d, multicast_in_multicast_coord_d)
    begin
        x_next  <= '0';
        y_next  <= '0';
     
        -- Only route multicast packets out of multicast_out
        if (x_in_valid_d = '1' and is_valid_packet_in(x_in_dest_d, x_in_valid_d) = False
                and is_valid_multicast_in(multicast_in_multicast_coord_d, multicast_in_valid_d) = True) then
            x_next <= '0';
            
        elsif (pe_in_valid_d = '1' and is_valid_packet_in(pe_in_dest_d, pe_in_valid_d) = False
                and is_valid_multicast_in(pe_in_multicast_coord_d, pe_in_valid_d) = True) then
            x_next <= '0';

        elsif (x_in_valid_d = '1' and is_valid_packet_in(x_in_dest_d, x_in_valid_d) = False) then
            x_next <= '1';
            
        elsif (pe_in_valid_d = '1' and is_valid_packet_in(pe_in_dest_d, pe_in_valid_d) = True) then
            x_next <= '0';
            
        else
            x_next <= pe_in_valid_d;
            
        end if;

        -- Only route multicast packet out of y_out if multicast_out is already used
        if (y_in_valid_d = '0' and x_in_valid_d = '1' and is_valid_packet_in(x_in_dest_d, x_in_valid_d) = False
                and is_valid_multicast_in(x_in_multicast_coord_d, x_in_valid_d) = True) then
            y_next <= '0';
            
        elsif (pe_in_valid_d = '1' and is_valid_packet_in(pe_in_dest_d, pe_in_valid_d) = False
                and is_valid_multicast_in(pe_in_multicast_coord_d, pe_in_valid_d) = True) then
            y_next <= '0';
        
        -- Switch y_out to act as pe_out
        elsif (x_in_valid_d = '1' and is_valid_packet_in(x_in_dest_d, x_in_valid_d) = True) then
                
            -- Both x_in and y_in are destined for the PE, so y_in must be deflected
            if (y_in_valid_d = '1' and is_valid_packet_in(y_in_dest_d, y_in_valid_d) = True) then
                y_next <= '1';
            -- multicast_in is destined for the PE, so y_in must be deflected
            elsif (multicast_in_valid_d = '1' 
                        and is_valid_multicast_in(multicast_in_multicast_coord_d, multicast_in_valid_d) = True) then
                y_next <= '1';
            else
                y_next <= '0';
            end if;
            
        elsif (y_in_valid_d = '1' and is_valid_packet_in(y_in_dest_d, y_in_valid_d) = True) then
                
            -- multicast_in is destined for the PE, so y_in must be deflected
            if (multicast_in_valid_d = '1' 
                        and is_valid_multicast_in(multicast_in_multicast_coord_d, multicast_in_valid_d) = True) then
                
                -- Route y_in out of multicast_out only 
                if (is_valid_multicast_in(y_in_multicast_coord_d, y_in_valid_d) = True) then
                    y_next <= '0';
                else
                    y_next <= '1';
                end if;  
            else
                y_next <= '0';
            end if;
            
        elsif (y_in_valid_d = '1' and is_valid_packet_in(y_in_dest_d, y_in_valid_d) = False) then
            -- Route y_in out of multicast_out only 
            if (is_valid_multicast_in(y_in_multicast_coord_d, y_in_valid_d) = True) then
                y_next <= '0';
            else
                y_next <= '1';
            end if;  
            
        elsif (x_in_valid_d = '1' and is_valid_packet_in(x_in_dest_d, x_in_valid_d) = False) then
            y_next <= '1';
        
        elsif (pe_in_valid_d = '1' and is_valid_packet_in(pe_in_dest_d, pe_in_valid_d) = True) then
            
            -- multicast_in is destined for the PE, so y_in must be deflected
            if (multicast_in_valid_d = '1' 
                    and is_valid_multicast_in(multicast_in_multicast_coord_d, multicast_in_valid_d) = True) then
                y_next <= '1';
            else
                y_next <= '0';
            end if;
            
        else
            y_next <= pe_in_valid_d;
            
        end if;
    end process NEXT_VALID;
    
    -- Valid signal routing    
    OUTPUT_VALID_FF: process(clk)
    begin
        if (rising_edge(clk)) then
            if (reset_n = '0') then
                x_out_valid <= '0';
                y_out_valid <= '0';
            else
                -- Multicast out of both x_out and y_out not possible
                if (y_in_valid = '1') then
                    x_out_valid <= x_next;
                    y_out_valid <= y_next;
                elsif (to_integer(unsigned(x_in_dest_d(X_INDEX))) /= X_COORD) then
                    x_out_valid <= x_next;
                    y_out_valid <= '0';
                elsif (to_integer(unsigned(x_in_dest_d(Y_INDEX))) /= Y_COORD) then
                    x_out_valid <= '0';
                    y_out_valid <= y_next;
                else
                    x_out_valid <= x_next;
                    y_out_valid <= y_next;
                end if;
            end if;
        end if;
    end process OUTPUT_VALID_FF;     
    
end Behavioral;
