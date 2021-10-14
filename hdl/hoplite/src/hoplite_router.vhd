library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity hoplite_router is
    Generic (
        BUS_WIDTH   : integer := 32;
        X_COORD     : integer := 0;
        Y_COORD     : integer := 0;
        COORD_BITS  : integer := 1
    );
    Port ( 
        clk             : in STD_LOGIC;
        reset_n         : in STD_LOGIC;
        
        -- Input
        x_in            : in STD_LOGIC_VECTOR((BUS_WIDTH-1) downto 0);
        x_in_valid      : in STD_LOGIC;
        y_in            : in STD_LOGIC_VECTOR((BUS_WIDTH-1) downto 0);
        y_in_valid      : in STD_LOGIC;
        pe_in           : in STD_LOGIC_VECTOR((BUS_WIDTH-1) downto 0);
        pe_in_valid     : in STD_LOGIC;
        pe_backpressure : out STD_LOGIC;
        
        -- Output
        x_out           : out STD_LOGIC_VECTOR((BUS_WIDTH-1) downto 0);
        x_out_valid     : out STD_LOGIC;
        y_out           : out STD_LOGIC_VECTOR((BUS_WIDTH-1) downto 0);
        y_out_valid     : out STD_LOGIC;
        pe_out          : out STD_LOGIC_VECTOR((BUS_WIDTH-1) downto 0);
        pe_out_valid    : out STD_LOGIC
    );
end hoplite_router;

architecture Behavioral of hoplite_router is
    
    signal x_d, x_q, y_d, y_q, pe_d : std_logic_vector((BUS_WIDTH-1) downto 0);
    signal sel : std_logic_vector(1 downto 0);
    signal x_next, y_next : std_logic;
    
    signal x_in_valid_d, y_in_valid_d, pe_in_valid_d : std_logic;
    
    type t_Coordinate is array (0 to 1) of std_logic_vector((COORD_BITS-1) downto 0);
    constant X_INDEX    : integer := 0;
    constant Y_INDEX    : integer := 1;
    signal x_in_dest_d, y_in_dest_d, pe_in_dest_d : t_Coordinate;
    signal x_in_dest_q, y_in_dest_q, pe_in_dest_q : t_Coordinate;
    
    constant X_INDEX_HEADER_START   : integer := 0;
    constant X_INDEX_HEADER_END     : integer := COORD_BITS-1;
    
    constant Y_INDEX_HEADER_START   : integer := COORD_BITS;
    constant Y_INDEX_HEADER_END     : integer := 2*COORD_BITS-1;
    
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

begin

    -- Assign destination coordinates   
    x_in_dest_d(X_INDEX) <= x_d(X_INDEX_HEADER_END downto X_INDEX_HEADER_START);
    x_in_dest_d(Y_INDEX) <= x_d(Y_INDEX_HEADER_END downto Y_INDEX_HEADER_START);
    
    y_in_dest_d(X_INDEX) <= y_d(X_INDEX_HEADER_END downto X_INDEX_HEADER_START);
    y_in_dest_d(Y_INDEX) <= y_d(Y_INDEX_HEADER_END downto Y_INDEX_HEADER_START);
    
    pe_in_dest_d(X_INDEX) <= pe_d(X_INDEX_HEADER_END downto X_INDEX_HEADER_START);
    pe_in_dest_d(Y_INDEX) <= pe_d(Y_INDEX_HEADER_END downto Y_INDEX_HEADER_START);
    
    x_in_valid_d    <= x_in_valid;
    y_in_valid_d    <= y_in_valid;
    pe_in_valid_d   <= pe_in_valid;

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
               
    -- Apply backpressure to the connected PE
    with sel select
        pe_backpressure <=  '0' when "00",
                            '1' when "10",
                            '1' when others;
    
    OUTPUT_FF : process (clk)
    begin
        if (rising_edge(clk)) then
            if (reset_n = '0') then
                x_q         <= (others => '0');
                y_q         <= (others => '0');
                
                pe_out      <= (others => '0');
                pe_out_valid    <= '0';
            else
                x_q <= x_d;
                y_q <= y_d;
               
                if (is_valid_packet_in(pe_in_dest_d, pe_in_valid) = True) then
                    pe_out_valid    <= '1'; 
                    pe_out          <= pe_d;
               
                elsif (is_valid_packet_in(x_in_dest_d, x_in_valid) = True) then
                    pe_out_valid    <= '1'; 
                    pe_out          <= x_d;
                    
                elsif (is_valid_packet_in(y_in_dest_d, y_in_valid) = True) then
                    pe_out_valid    <= '1';
                    pe_out          <= y_d;
                
                else
                    pe_out_valid    <= '0';
                    
                end if;
            end if;
        end if;
    end process OUTPUT_FF;
        
    -- Output to X and Y links
    x_out <= x_q;
    y_out <= y_q;

     NEXT_VALID: process (x_in_valid_d, y_in_valid_d, x_in_dest_d, y_in_dest_d, pe_in_valid_d, pe_in_dest_d)
     begin
        x_next  <= '0';
        y_next  <= '0';
     
        if (x_in_valid_d = '1' and is_valid_packet_in(x_in_dest_d, x_in_valid) = False) then
            x_next <= '1';
        elsif (pe_in_valid_d = '1' and is_valid_packet_in(pe_in_dest_d, pe_in_valid_d) = True) then
            x_next <= '0';
        else
            x_next <= pe_in_valid_d;
        end if;
        
        -- Switch y_out to act as pe_out
        if (x_in_valid_d = '1' and is_valid_packet_in(x_in_dest_d, x_in_valid_d) = True) then
            -- Both x_in and y_in are destined for the PE, so y_in must be deflected
            if (y_in_valid_d = '1' and is_valid_packet_in(y_in_dest_d, y_in_valid_d) = True) then
                y_next <= '1';
            else
                y_next <= '0';
            end if;
            
        elsif (y_in_valid_d = '1' and is_valid_packet_in(y_in_dest_d, y_in_valid_d) = True) then
            y_next <= '0';
            
        elsif (y_in_valid_d = '1' and is_valid_packet_in(y_in_dest_d, y_in_valid_d) = False) then
            y_next <= '1';
            
        elsif (x_in_valid_d = '1' and is_valid_packet_in(x_in_dest_d, x_in_valid_d) = False) then
            y_next <= '1';
        
        elsif (pe_in_valid_d = '1' and is_valid_packet_in(pe_in_dest_d, pe_in_valid_d) = True) then
            y_next <= '0';
            
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
                -- Multicast not possible
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
