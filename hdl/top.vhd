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
           RGB1_Red     : out STD_LOGIC);
end top;

architecture Behavioral of top is

--    component picorv32_axi
--    generic (
--        ENABLE_MUL  : std_logic := '1'
--    );
--    port (
--        clk     : in std_logic;
--        resetn  : in std_logic;
--        trap    : out std_logic;
        
--        mem_axi_awvalid : out std_logic;
--        mem_axi_awready : in std_logic;
--        mem_axi_awaddr  : out std_logic_vector(31 downto 0);
--        mem_axi_awprot  : out std_logic_vector(2 downto 0);
        
--        mem_axi_wvalid   : out std_logic;
--        mem_axi_wready  : in std_logic;
--        mem_axi_wdata   : out std_logic_vector(31 downto 0);
--        mem_axi_wstrb   : out std_logic_vector(3 downto 0);
        
--        mem_axi_bvalid : in std_logic;
--        mem_axi_bready : out std_logic;
        
--        mem_axi_arvalid : out std_logic;
--        mem_axi_arready : in std_logic;
--        mem_axi_araddr : out std_logic_vector(31 downto 0);
--        mem_axi_arprot : out std_logic_vector(2 downto 0);
        
--        mem_axi_rvalid : in std_logic;
--        mem_axi_rready : out std_logic;
--        mem_axi_rdata : in std_logic_vector(31 downto 0);
        
--        pcpi_valid : out std_logic;
--        pcpi_insn : out std_logic_vector(31 downto 0);
--        pcpi_rs1 : out std_logic_vector(31 downto 0);
--        pcpi_rs2 : out std_logic_vector(31 downto 0);
--        pcpi_wr : in std_logic;
--        pcpi_rd : in std_logic_vector(31 downto 0);
--        pcpi_wait : in std_logic;
--        pcpi_ready : in std_logic;
        
--        irq : in std_logic_vector(31 downto 0);
--        eoi : out std_logic_vector(31 downto 0);
        
--        trace_valid : out std_logic;
--        trace_data : out std_logic_vector(35 downto 0)
--    );
--    end component picorv32_axi;

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
            clk     => clk,
            resetn  => btnCpuReset,
            led     => led,
            RGB_LED => RGB1_Red,
            out_byte_en => open,
            out_byte => open,
            trap => open
        );

--    CPU_1 : picorv32_axi
--        port map (
--            clk             => clk,
--            resetn          => '0',
--            trap            => open,
            
--            mem_axi_awvalid => open,
--            mem_axi_awready => '0',
--            mem_axi_awaddr  => open,
--            mem_axi_awprot  => open,
            
--            mem_axi_wvalid   => open,
--            mem_axi_wready  => '0',
--            mem_axi_wdata   => open,
--            mem_axi_wstrb   => open,
            
--            mem_axi_bvalid  => '0',
--            mem_axi_bready  => open,
            
--            mem_axi_arvalid => open,
--            mem_axi_arready => '0',
--            mem_axi_araddr  => open,
--            mem_axi_arprot  => open,
            
--            mem_axi_rvalid  => '0',
--            mem_axi_rready  => open,
--            mem_axi_rdata   => (31 downto 0 => '0'),
            
--            pcpi_valid      => open,
--            pcpi_insn       => open,
--            pcpi_rs1        => open,
--            pcpi_rs2        => open,
--            pcpi_wr         => '0',
--            pcpi_rd         => (31 downto 0 => '0'),
--            pcpi_wait       => '0',
--            pcpi_ready      => '0',
            
--            irq             => (31 downto 0 => '0'),
--            eoi             => open,
            
--            trace_valid     => open,
--            trace_data      => open
--        );
        
--    CPU_2 : picorv32_axi
--        port map (
--            clk             => clk,
--            resetn          => '0',
--            trap            => open,
            
--            mem_axi_awvalid => open,
--            mem_axi_awready => '0',
--            mem_axi_awaddr  => open,
--            mem_axi_awprot  => open,
            
--            mem_axi_wvalid   => open,
--            mem_axi_wready  => '0',
--            mem_axi_wdata   => open,
--            mem_axi_wstrb   => open,
            
--            mem_axi_bvalid  => '0',
--            mem_axi_bready  => open,
            
--            mem_axi_arvalid => open,
--            mem_axi_arready => '0',
--            mem_axi_araddr  => open,
--            mem_axi_arprot  => open,
            
--            mem_axi_rvalid  => '0',
--            mem_axi_rready  => open,
--            mem_axi_rdata   => (31 downto 0 => '0'),
            
--            pcpi_valid      => open,
--            pcpi_insn       => open,
--            pcpi_rs1        => open,
--            pcpi_rs2        => open,
--            pcpi_wr         => '0',
--            pcpi_rd         => (31 downto 0 => '0'),
--            pcpi_wait       => '0',
--            pcpi_ready      => '0',
            
--            irq             => (31 downto 0 => '0'),
--            eoi             => open,
            
--            trace_valid     => open,
--            trace_data      => open
--        );
        
--    CPU_3 : picorv32_axi
--        port map (
--            clk             => clk,
--            resetn          => '0',
--            trap            => open,
            
--            mem_axi_awvalid => open,
--            mem_axi_awready => '0',
--            mem_axi_awaddr  => open,
--            mem_axi_awprot  => open,
            
--            mem_axi_wvalid   => open,
--            mem_axi_wready  => '0',
--            mem_axi_wdata   => open,
--            mem_axi_wstrb   => open,
            
--            mem_axi_bvalid  => '0',
--            mem_axi_bready  => open,
            
--            mem_axi_arvalid => open,
--            mem_axi_arready => '0',
--            mem_axi_araddr  => open,
--            mem_axi_arprot  => open,
            
--            mem_axi_rvalid  => '0',
--            mem_axi_rready  => open,
--            mem_axi_rdata   => (31 downto 0 => '0'),
            
--            pcpi_valid      => open,
--            pcpi_insn       => open,
--            pcpi_rs1        => open,
--            pcpi_rs2        => open,
--            pcpi_wr         => '0',
--            pcpi_rd         => (31 downto 0 => '0'),
--            pcpi_wait       => '0',
--            pcpi_ready      => '0',
            
--            irq             => (31 downto 0 => '0'),
--            eoi             => open,
            
--            trace_valid     => open,
--            trace_data      => open
--        );
        
--    CPU_4 : picorv32_axi
--        port map (
--            clk             => clk,
--            resetn          => '0',
--            trap            => open,
            
--            mem_axi_awvalid => open,
--            mem_axi_awready => '0',
--            mem_axi_awaddr  => open,
--            mem_axi_awprot  => open,
            
--            mem_axi_wvalid   => open,
--            mem_axi_wready  => '0',
--            mem_axi_wdata   => open,
--            mem_axi_wstrb   => open,
            
--            mem_axi_bvalid  => '0',
--            mem_axi_bready  => open,
            
--            mem_axi_arvalid => open,
--            mem_axi_arready => '0',
--            mem_axi_araddr  => open,
--            mem_axi_arprot  => open,
            
--            mem_axi_rvalid  => '0',
--            mem_axi_rready  => open,
--            mem_axi_rdata   => (31 downto 0 => '0'),
            
--            pcpi_valid      => open,
--            pcpi_insn       => open,
--            pcpi_rs1        => open,
--            pcpi_rs2        => open,
--            pcpi_wr         => '0',
--            pcpi_rd         => (31 downto 0 => '0'),
--            pcpi_wait       => '0',
--            pcpi_ready      => '0',
            
--            irq             => (31 downto 0 => '0'),
--            eoi             => open,
            
--            trace_valid     => open,
--            trace_data      => open
--        );

end Behavioral;
