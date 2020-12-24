-- first_wb.vhd 

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library pipe_proc;
use pipe_proc.pipe_proc_pkg.all;

entity first_wb is
    generic ( G_SIM: integer := 0);
    port (
        aclr : in std_logic;
        sclr : in std_logic;
        clk : in std_logic;
        clk_ena : in std_logic;
         
        EX_valid : in std_logic;
        EX_ALU_out : in data_t;
        EX_rf_waddr : in std_logic_vector(3 downto 0);
        EX_rf_wena : in std_logic;
        EX_rf_adata : in data_t;
        EX_MEM_rf_wena : in std_logic;
        EX_suppress_src : in std_logic_vector(1 downto 0);
        EX_pc_setena : in std_logic;
        EX_pc : in data_t;
        EX_MEM_pc_setena : in std_logic; 
        EX_mem_addr_src : in std_logic;
        EX_mem_wdata_src : in std_logic_vector(1 downto 0);
        EX_mem_wena : in std_logic;
        EX_sp_inc : in std_logic;
        EX_sp_dec : in std_logic;
        EX_sp_setena : in std_logic;
        EX_mem_rena : in std_logic;
        EX_halt : in std_logic;
        EX_reset : in std_logic;
        EX_clr : in std_logic;
        
        mem_rdata : in data_t;
        sp : in data_t;
        
        -- these are control signals, which will go to other stages
        WB_rf_wdata : out data_t; 
        WB_rf_waddr : out std_logic_vector(3 downto 0);
        WB_rf_wena : out std_logic;
        WB_rf_wdata2 : out data_t; 
        WB_rf_waddr2 : out std_logic_vector(3 downto 0);
        WB_rf_wena2 : out std_logic;
        WB_suppress : out std_logic;
        WB_pc_setv : out data_t;
        WB_pc_setena : out std_logic;
        WB_mem_addr : out data_t;
        WB_mem_wdata : out data_t;
        WB_mem_wena : out std_logic;
        WB_sp_inc : out std_logic;
        WB_sp_dec : out std_logic;
        WB_sp_setv : out data_t;
        WB_sp_setena : out std_logic;
        WB_mem_rena : out std_logic;
        WB_halt : out std_logic;
        WB_reset : out std_logic;
        WB_clr : out std_logic;
        
        MEM_valid_out : out std_logic;
        MEM_rf_waddr_out : out std_logic_vector(3 downto 0);
        MEM_rf_wena_out : out std_logic;
        MEM_pc_setena_out : out std_logic
        
    );
    
end entity;

architecture rtl of first_wb is

signal MEM_valid : std_logic;
signal MEM_rf_waddr : std_logic_vector(3 downto 0);
signal MEM_rf_wena : std_logic; 
signal MEM_pc_setena : std_logic;

begin

MEM_valid_out <= MEM_valid;
MEM_rf_waddr_out <= MEM_rf_waddr;
MEM_rf_wena_out <= MEM_rf_wena;
MEM_pc_setena_out <= MEM_pc_setena;

WB_rf_wdata <= EX_ALU_out;
WB_rf_waddr <= EX_rf_waddr;
WB_rf_wena <= EX_rf_wena when (EX_valid = '1') else '0';
WB_rf_wdata2 <= mem_rdata when (MEM_valid = '1') else EX_ALU_out;
WB_rf_waddr2 <= MEM_rf_waddr when (MEM_valid = '1') else EX_rf_waddr;
WB_rf_wena2 <= MEM_rf_wena when (MEM_valid = '1') else '0';
WB_suppress <= EX_ALU_out(0) when ((EX_suppress_src = "10") and (EX_valid = '1')) else EX_suppress_src(0) when (EX_valid = '1') else '0'; -- idk about the EX_suppress_src(0) thing
WB_pc_setv <= mem_rdata when ((MEM_pc_setena = '1') and (MEM_valid = '1')) else x"0000" when (EX_reset = '1') else EX_ALU_out;
WB_pc_setena <= MEM_pc_setena when ((MEM_pc_setena = '1') and (MEM_valid = '1')) else '1' when (EX_reset = '1') else EX_pc_setena when (EX_valid = '1') else '0';
WB_mem_addr <= sp when (EX_mem_addr_src = '0') else EX_ALU_out; -- this is reliant on correct default behavior for reads - hopefully this works
WB_mem_wdata <= EX_ALU_out when (EX_mem_wdata_src = "00") else EX_pc when (EX_mem_wdata_src = "01") else EX_rf_adata;
WB_mem_wena <= EX_mem_wena when (EX_valid = '1') else '0';
WB_sp_inc <= EX_sp_inc when (EX_valid = '1') else '0';
WB_sp_dec <= EX_sp_dec when (EX_valid = '1') else '0';
WB_sp_setv <= x"ffff" when (EX_reset = '1') else EX_ALU_out;
WB_sp_setena <= '1' when (EX_reset = '1') else EX_sp_setena when (EX_valid = '1') else '0';
WB_mem_rena <= EX_mem_rena when (EX_valid = '1') else '0';
WB_halt <= EX_halt when (EX_valid = '1') else '0';
WB_reset <= EX_reset when (EX_valid = '1') else '0';
WB_clr <= EX_clr when (EX_valid = '1') else '0';

reg_fwb : process (clk)
begin
    if RISING_EDGE(clk) then
        if (sclr = '1') then
            MEM_valid <= '0';
        elsif (clk_ena = '1') then
            MEM_valid <= EX_valid;
            MEM_rf_waddr <= EX_rf_waddr;
            MEM_rf_wena <= EX_MEM_rf_wena;
            MEM_pc_setena <= EX_MEM_pc_setena;
        end if;
    end if;
end process;

end architecture;