library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

package packet_defs is 

    constant MULTICAST_GROUP_BITS   : integer := 1;

    -- Size of message data in packets
    constant COORD_BITS             : integer := 2;
    constant MULTICAST_COORD_BITS   : integer := 2;
    constant DONE_FLAG_BITS         : integer := 1;
    constant RESULT_FLAG_BITS       : integer := 1;
    constant MATRIX_TYPE_BITS       : integer := 1;
    constant MATRIX_COORD_BITS      : integer := 8;
    constant MATRIX_ELEMENT_BITS    : integer := 32;
    constant BUS_WIDTH              : integer := 
            2*COORD_BITS + 2*MULTICAST_COORD_BITS + DONE_FLAG_BITS + 
            RESULT_FLAG_BITS + MATRIX_TYPE_BITS + 2*MATRIX_COORD_BITS + 
            MATRIX_ELEMENT_BITS;

    constant X_INDEX    : integer := 0;
    constant Y_INDEX    : integer := 1;

    type t_MulticastCoordinate is array (0 to 1) of std_logic_vector((MULTICAST_COORD_BITS-1) downto 0);
    type t_Coordinate is array (0 to 1) of std_logic_vector((COORD_BITS-1) downto 0);
    type t_MatrixCoordinate is array (0 to 1) of std_logic_vector((MATRIX_COORD_BITS-1) downto 0);

    -- Packet field indices
    constant X_COORD_START  : integer := 0;
    constant X_COORD_END    : integer := X_COORD_START + COORD_BITS - 1;

    constant Y_COORD_START  : integer := X_COORD_END + 1;
    constant Y_COORD_END    : integer := Y_COORD_START + COORD_BITS - 1;

    constant MULTICAST_X_COORD_START  : integer := Y_COORD_END + 1;
    constant MULTICAST_X_COORD_END    : integer := MULTICAST_X_COORD_START + MULTICAST_COORD_BITS - 1;

    constant MULTICAST_Y_COORD_START  : integer := MULTICAST_X_COORD_END + 1;
    constant MULTICAST_Y_COORD_END    : integer := MULTICAST_Y_COORD_START + MULTICAST_COORD_BITS - 1;

    constant DONE_FLAG_BIT          : integer := MULTICAST_Y_COORD_END + 1;

    constant RESULT_FLAG_BIT        : integer := DONE_FLAG_BIT + 1;

    constant MATRIX_TYPE_START      : integer := RESULT_FLAG_BIT + 1;
    constant MATRIX_TYPE_END        : integer := MATRIX_TYPE_START + MATRIX_TYPE_BITS - 1;

    constant MATRIX_X_COORD_START   : integer := MATRIX_TYPE_END + 1;
    constant MATRIX_X_COORD_END     : integer := MATRIX_X_COORD_START + MATRIX_COORD_BITS - 1;

    constant MATRIX_Y_COORD_START   : integer := MATRIX_X_COORD_END + 1;
    constant MATRIX_Y_COORD_END     : integer := MATRIX_Y_COORD_START + MATRIX_COORD_BITS - 1;

    constant MATRIX_ELEMENT_START   : integer := MATRIX_Y_COORD_END + 1;
    constant MATRIX_ELEMENT_END     : integer := MATRIX_ELEMENT_START + MATRIX_ELEMENT_BITS - 1;

    -- Packet field access functions
    function get_dest_coord (packet : in std_logic_vector) 
        return t_Coordinate;
    
    function get_multicast_coord (packet : in std_logic_vector)
        return t_MulticastCoordinate;
        
    function get_done_flag (packet : in std_logic_vector)
        return std_logic;
        
    function get_result_flag (packet : in std_logic_vector)
        return std_logic;
        
    function get_matrix_type (packet : in std_logic_vector)
        return std_logic_vector;

    function get_matrix_coord (packet : in std_logic_vector)
        return t_MatrixCoordinate;

    function get_matrix_element (packet : in std_logic_vector)
        return std_logic_vector;

end package packet_defs;


package body packet_defs is
    
    function get_dest_coord (packet : in std_logic_vector) return t_Coordinate is
        variable destination : t_Coordinate;
    begin
        destination(X_INDEX)    := packet(X_COORD_END downto X_COORD_START);
        destination(Y_INDEX)    := packet(Y_COORD_END downto Y_COORD_START);
        
        return destination;
    end function get_dest_coord;
    
    function get_multicast_coord (packet : in std_logic_vector) return t_MulticastCoordinate is
        variable multicastCoord : t_MulticastCoordinate;
    begin
        multicastCoord(X_INDEX) := packet(MULTICAST_X_COORD_END downto MULTICAST_X_COORD_START);
        multicastCoord(Y_INDEX) := packet(MULTICAST_Y_COORD_END downto MULTICAST_Y_COORD_START);
        
        return multicastCoord;
    end function get_multicast_coord;

    function get_done_flag (packet : in std_logic_vector) return std_logic is
        variable doneFlag : std_logic;
    begin
        doneFlag  := packet(DONE_FLAG_BIT);

        return doneFlag;
    end function get_done_flag;
    
    function get_result_flag (packet : in std_logic_vector) return std_logic is
        variable resultFlag : std_logic;
    begin
        resultFlag  := packet(RESULT_FLAG_BIT);

        return resultFlag;
    end function get_result_flag;
        
    function get_matrix_type (packet : in std_logic_vector) return std_logic_vector is
        variable matrixType : std_logic_vector((MATRIX_TYPE_BITS-1) downto 0);
    begin
        matrixType  := packet(MATRIX_TYPE_END downto MATRIX_TYPE_START);

        return matrixType;
    end function get_matrix_type;

    function get_matrix_coord (packet : in std_logic_vector) return t_MatrixCoordinate is
        variable matrixCoord   : t_MatrixCoordinate;
    begin
        matrixCoord(X_INDEX)    := packet(MATRIX_X_COORD_END downto MATRIX_X_COORD_START);
        matrixCoord(Y_INDEX)    := packet(MATRIX_Y_COORD_END downto MATRIX_Y_COORD_START);
        
        return matrixCoord;
    end function get_matrix_coord;

    function get_matrix_element (packet : in std_logic_vector) return std_logic_vector is
        variable matrixElement  : std_logic_vector((MATRIX_ELEMENT_BITS-1) downto 0);
    begin
        matrixElement   := packet(MATRIX_ELEMENT_END downto MATRIX_ELEMENT_START);

        return matrixElement;
    end function get_matrix_element;

end package body packet_defs;