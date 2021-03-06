library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.math_real.all;

use STD.textio.all;
use IEEE.std_logic_textio.all;

library xil_defaultlib;
use xil_defaultlib.hoplite_network_tb_defs.all;

entity hoplite_unicast_tb_pe is
    Generic (
        X_COORD     : integer := 0;
        Y_COORD     : integer := 0;
        COORD_BITS  : integer := 2;
        BUS_WIDTH   : integer := 8
    );
    Port ( 
        clk                     : in std_logic;
        reset_n                 : in std_logic;
        
        count                   : in integer;
        trig                    : in std_logic;
        trig_broadcast          : in std_logic;
        
        x_dest                  : in std_logic_vector((COORD_BITS-1) downto 0);
        y_dest                  : in std_logic_vector((COORD_BITS-1) downto 0);
        
        message_out             : out std_logic_vector ((BUS_WIDTH-1) downto 0);
        message_out_valid       : out std_logic;
        
        message_in              : in std_logic_vector ((BUS_WIDTH-1) downto 0);
        message_in_valid        : in std_logic;
        
        last_message_sent       : out std_logic_vector ((BUS_WIDTH-1) downto 0);
        message_sent            : out std_logic;
        
        last_message_received   : out std_logic_vector ((BUS_WIDTH-1) downto 0);
        message_received        : out std_logic
   );
end hoplite_unicast_tb_pe;

architecture Behavioral of hoplite_unicast_tb_pe is

    constant x_src : std_logic_vector((COORD_BITS-1) downto 0) := std_logic_vector(to_unsigned(X_COORD, COORD_BITS));
    constant y_src : std_logic_vector((COORD_BITS-1) downto 0) := std_logic_vector(to_unsigned(Y_COORD, COORD_BITS));

    constant src    : t_Coordinate := (X_INDEX => x_src, Y_INDEX => y_src);
    signal dest     : t_Coordinate;

    signal message  : std_logic_vector((BUS_WIDTH-1) downto 0);
    
    signal received_src, received_dest  : t_Coordinate;
    signal received_message             : std_logic_vector((MESSAGE_BITS-1) downto 0);
    signal received_type                : std_logic;

begin

    dest(X_INDEX) <= x_dest; 
    dest(Y_INDEX) <= y_dest;

    -- Message format 0 -- x_dest | y_dest | x_src | y_src | count | type -- (BUS_WIDTH-1)
    message <= trig_broadcast & trig_broadcast & trig_broadcast & trig_broadcast & trig_broadcast & std_logic_vector(to_unsigned(count, MESSAGE_BITS)) & src(Y_INDEX) & src(X_INDEX) & dest(Y_INDEX) & dest(X_INDEX);

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
    
    TRIGGER: process (clk)
        variable my_line : line;
    begin
        if (rising_edge(clk) and reset_n = '1' and trig = '1') then
            write(my_line, string'(HT & "hoplite_unicast_tb_pe: "));
        
            write(my_line, string'("Node ("));
            write(my_line, X_COORD);
            
            write(my_line, string'(", "));
            write(my_line, Y_COORD);
            write(my_line, string'(")"));
            
            write(my_line, string'(", Cycle Count = "));
            write(my_line, count);
            
            writeline(output, my_line);
        
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
            
            writeline(output, my_line);
        end if;
    end process TRIGGER;

    -- Print message_in to stdout if it is valid
    received_src(Y_INDEX)   <= message_in((4*COORD_BITS-1) downto 3*COORD_BITS);
    received_src(X_INDEX)   <= message_in((3*COORD_BITS-1) downto 2*COORD_BITS);
    received_dest(Y_INDEX)  <= message_in((2*COORD_BITS-1) downto COORD_BITS);
    received_dest(X_INDEX)  <= message_in((COORD_BITS-1) downto 0);
    received_message        <= message_in((BUS_WIDTH-MESSAGE_TYPE_BITS-1) downto 4*COORD_BITS + 2*MULTICAST_COORD_BITS);
    received_type           <= message_in(BUS_WIDTH-1);
    
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
            write(my_line, string'(HT & "hoplite_unicast_tb_pe: "));
        
            write(my_line, string'("Node ("));
            write(my_line, X_COORD);
            
            write(my_line, string'(", "));
            write(my_line, Y_COORD);
            write(my_line, string'(")"));
            
            write(my_line, string'(", Cycle Count = "));
            write(my_line, count);
            
            writeline(output, my_line);
        
            write(my_line, string'(HT & HT & "Source X = "));
            write(my_line, to_integer(unsigned(received_src(X_INDEX))));
            
            write(my_line, string'(", Source Y = "));
            write(my_line, to_integer(unsigned(received_src(Y_INDEX))));
            
            write(my_line, string'(", Destination X = "));
            write(my_line, to_integer(unsigned(received_dest(X_INDEX))));
            
            write(my_line, string'(", Destination Y = "));
            write(my_line, to_integer(unsigned(received_dest(Y_INDEX))));
            
            write(my_line, string'(", Count = "));
            write(my_line, to_integer(unsigned(received_message)));
            
            write(my_line, string'(", Type = "));
            if (received_type = '1') then
                write(my_line, string'("Broadcast"));
            else
                write(my_line, string'("Unicast"));
            end if;
            
            write(my_line, string'(", Raw = "));
            write(my_line, message_in);
            
            writeline(output, my_line);
        end if;
    end process PRINT_MESSAGE_RECEIVED;
    
end Behavioral;
