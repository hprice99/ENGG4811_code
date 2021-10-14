library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.math_real.all;

use STD.textio.all;
use IEEE.std_logic_textio.all;

library xil_defaultlib;
use xil_defaultlib.hoplite_network_tb_defs.all;

entity hoplite_multicast_tb_pe is
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
        clk                     : in STD_LOGIC;
        reset_n                 : in STD_LOGIC;
        
        count                   : in integer;
        trig                    : in STD_LOGIC;
        trig_broadcast          : in STD_LOGIC;
        
        x_dest                  : in STD_LOGIC_VECTOR((COORD_BITS-1) downto 0);
        y_dest                  : in STD_LOGIC_VECTOR((COORD_BITS-1) downto 0);
        
        message_out             : out STD_LOGIC_VECTOR ((BUS_WIDTH-1) downto 0);
        message_out_valid       : out STD_LOGIC;
        
        message_in              : in STD_LOGIC_VECTOR ((BUS_WIDTH-1) downto 0);
        message_in_valid        : in STD_LOGIC;
        
        last_message_sent       : out STD_LOGIC_VECTOR ((BUS_WIDTH-1) downto 0);
        message_sent            : out STD_LOGIC;
        
        last_message_received   : out STD_LOGIC_VECTOR ((BUS_WIDTH-1) downto 0);
        message_received        : out STD_LOGIC
   );
end hoplite_multicast_tb_pe;

architecture Behavioral of hoplite_multicast_tb_pe is

    constant x_src : std_logic_vector((COORD_BITS-1) downto 0) := std_logic_vector(to_unsigned(X_COORD, COORD_BITS));
    constant y_src : std_logic_vector((COORD_BITS-1) downto 0) := std_logic_vector(to_unsigned(Y_COORD, COORD_BITS));

    constant src    : t_Coordinate := (X_INDEX => x_src, Y_INDEX => y_src);
    signal dest     : t_Coordinate;
    
    constant multicast_x_dest   : std_logic_vector((MULTICAST_COORD_BITS-1) downto 0) := std_logic_vector(to_unsigned(MULTICAST_X_COORD, MULTICAST_COORD_BITS));
    constant multicast_y_dest   : std_logic_vector((MULTICAST_COORD_BITS-1) downto 0) := std_logic_vector(to_unsigned(MULTICAST_Y_COORD, MULTICAST_COORD_BITS));
    signal multicast_dest       : t_MulticastCoordinate;

    signal message  : std_logic_vector((BUS_WIDTH-1) downto 0);
    
    signal received_src, received_dest  : t_Coordinate;
    signal received_multicast_dest      : t_MulticastCoordinate;
    signal received_message             : std_logic_vector((MESSAGE_BITS-1) downto 0);
    signal received_type                : std_logic_vector((MESSAGE_TYPE_BITS-1) downto 0);
    
    impure function print_trigger (trig_broadcast : in std_logic; dest : in t_Coordinate) return line is
        variable my_line    : line;
    begin
        write(my_line, string'(HT & HT & "Trigger"));
        
        write(my_line, string'(", Type = "));
        if (trig_broadcast = '1') then
            write(my_line, string'("Broadcast"));
        else
            write(my_line, string'("Unicast"));
        end if;
        
        write(my_line, string'(", Destination X = "));
        write(my_line, to_integer(unsigned(dest(X_INDEX))));
        
        write(my_line, string'(", Destination Y = "));
        write(my_line, to_integer(unsigned(dest(Y_INDEX))));
        
        return my_line;
    end function print_trigger;
    
    impure function print_received_message (packet : in std_logic_vector) return line is
        variable destination            : t_Coordinate;
        variable multicast_destination  : t_MulticastCoordinate;
        variable source                 : t_Coordinate;
        variable message                : std_logic_vector((MESSAGE_BITS-1) downto 0);
        variable message_type           : std_logic_vector((MESSAGE_TYPE_BITS-1) downto 0);
        variable my_line    : line;
    begin
        destination             := get_dest_coord(packet);
        multicast_destination   := get_multicast_coord(packet);
        source                  := get_source_coord(packet);
        message                 := get_message(packet);
        message_type            := get_message_type(packet); 
    
        write(my_line, string'(HT & HT & "Source X = "));
        write(my_line, to_integer(unsigned(source(X_INDEX))));
        
        write(my_line, string'(", Source Y = "));
        write(my_line, to_integer(unsigned(source(Y_INDEX))));
        
        write(my_line, string'(", Destination X = "));
        write(my_line, to_integer(unsigned(destination(X_INDEX))));
        
        write(my_line, string'(", Destination Y = "));
        write(my_line, to_integer(unsigned(destination(Y_INDEX))));
        
        write(my_line, string'(", Count = "));
        write(my_line, to_integer(unsigned(message)));
        
        write(my_line, string'(", Type = "));
        if (message_type /= "0") then
            write(my_line, string'("Broadcast"));
        else
            write(my_line, string'("Unicast"));
        end if;
        
        write(my_line, string'(", Raw = "));
        write(my_line, packet);
        
        return my_line;
    end function print_received_message;

begin

    dest(X_INDEX) <= x_dest; 
    dest(Y_INDEX) <= y_dest;

    -- Message format 0 -- x_dest | y_dest | multicast_x_dest | multicast_y_dest | x_src | y_src | count | type -- (BUS_WIDTH-1)
    message <= trig_broadcast & std_logic_vector(to_unsigned(count, MESSAGE_BITS)) & src(Y_INDEX) & src(X_INDEX) & multicast_dest(Y_INDEX) & multicast_dest(X_INDEX) & dest(Y_INDEX) & dest(X_INDEX);

    MESSAGE_OUT_FF : process (clk)
    begin
        if (rising_edge(clk)) then
            if (reset_n = '0' or trig = '0') then            
                message_out         <= (others => '0');
                message_out_valid   <= '0';
                
                last_message_sent   <= (others => '0');
                message_sent        <= '0';
            elsif (trig = '1') then           
                message_out         <= message;
                message_out_valid   <= '1';
                
                last_message_sent   <= message;
                message_sent        <= '1';
            end if;
        end if;
    end process MESSAGE_OUT_FF;
    
    MULTICAST_DEST_PROC: process (trig_broadcast)
    begin
        if (trig_broadcast = '1') then
            multicast_dest(X_INDEX) <= multicast_x_dest;
            multicast_dest(Y_INDEX) <= multicast_y_dest;
        else
            multicast_dest(X_INDEX) <= (others => '0');
            multicast_dest(Y_INDEX) <= (others => '0');
        end if;
    end process MULTICAST_DEST_PROC;
    
    TRIGGER: process (clk)
        variable my_line : line;
    begin
        if (rising_edge(clk) and reset_n = '1' and trig = '1') then
            write(my_line, string'(HT & "hoplite_tb_pe: "));
        
            write(my_line, string'("Node ("));
            write(my_line, X_COORD);
            
            write(my_line, string'(", "));
            write(my_line, Y_COORD);
            write(my_line, string'(")"));
            
            write(my_line, string'(", Cycle Count = "));
            write(my_line, count);
            
            writeline(output, my_line);

            my_line := print_trigger(trig_broadcast, dest);
            
            writeline(output, my_line);
        end if;
    end process TRIGGER;

    -- Print message_in to stdout if it is valid
    received_dest           <= get_dest_coord(message_in);
    received_multicast_dest <= get_multicast_coord(message_in);
    received_src            <= get_source_coord(message_in);
    received_message        <= get_message(message_in);
    received_type           <= get_message_type(message_in);
    
    SAVE_MESSAGE_RECEIVED: process(clk)
    begin
        if (rising_edge(clk)) then
            if (reset_n = '0') then
                last_message_received <= (others => '0');
            else
                last_message_received <= message_in;
            end if;
        end if;
    end process SAVE_MESSAGE_RECEIVED;
    
    message_received <= message_in_valid;
    
    PRINT_MESSAGE_RECEIVED: process (clk)
        variable my_line : line;
    begin
        if (rising_edge(clk) and reset_n = '1' and message_in_valid = '1') then
            write(my_line, string'(HT & "hoplite_multicast_tb_pe: "));
        
            write(my_line, string'("Node ("));
            write(my_line, X_COORD);
            
            write(my_line, string'(", "));
            write(my_line, Y_COORD);
            write(my_line, string'(")"));
            
            write(my_line, string'(", Cycle Count = "));
            write(my_line, count);
            
            writeline(output, my_line);

            my_line := print_received_message(message_in);
            
            writeline(output, my_line);
        end if;
    end process PRINT_MESSAGE_RECEIVED;
    
end Behavioral;
