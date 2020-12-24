-- execute.vhd 

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library pipe_proc;
use pipe_proc.pipe_proc_pkg.all;

entity execute is
    generic ( G_SIM: integer := 0);
    port (
        aclr : in std_logic;
        sclr : in std_logic;
        clk : in std_logic;
        clk_ena : in std_logic;
         
        ID_valid : in std_logic;
        ALU_result_in : in data_t;
        ID_rf_waddr : in std_logic_vector(3 downto 0);
        ID_rf_wena : in std_logic;
        ID_rf_adata : in data_t;
        ID_MEM_rf_wena : in std_logic;
        ID_suppress_src : in std_logic_vector(1 downto 0);
        ID_pc_setena : in std_logic;
        ID_pc : in data_t;
        ID_MEM_pc_setena : in std_logic; 
        ID_mem_addr_src : in std_logic;
        ID_mem_wdata_src : in std_logic_vector(1 downto 0);
        ID_mem_wena : in std_logic;
        ID_sp_inc : in std_logic;
        ID_sp_dec : in std_logic;
        ID_sp_setena : in std_logic;
        ID_mem_rena : in std_logic;
        ID_halt : in std_logic;
        ID_reset : in std_logic;
        ID_clr : in std_logic;
        
        EX_valid : out std_logic;
        EX_ALU_result : out data_t;
        EX_rf_waddr : out std_logic_vector(3 downto 0);
        EX_rf_wena : out std_logic;
        EX_rf_adata : out data_t;
        EX_MEM_rf_wena : out std_logic;
        EX_suppress_src : out std_logic_vector(1 downto 0);
        EX_pc_setena : out std_logic;
        EX_pc : out data_t;
        EX_MEM_pc_setena : out std_logic; 
        EX_mem_addr_src : out std_logic;
        EX_mem_wdata_src : out std_logic_vector(1 downto 0);
        EX_mem_wena : out std_logic;
        EX_sp_inc : out std_logic;
        EX_sp_dec : out std_logic;
        EX_sp_setena : out std_logic;
        EX_mem_rena : out std_logic;
        EX_halt : out std_logic;
        EX_reset : out std_logic;
        EX_clr : out std_logic
    );
    
end entity;

architecture rtl of execute is
begin
    execute_reg : process(clk)
    begin
        if RISING_EDGE(clk) then
            if (sclr = '1') then
                EX_valid <= '0';
            elsif (clk_ena = '1') then
                EX_valid <= ID_valid;
                EX_ALU_result <= ALU_result_in;
                EX_rf_waddr <= ID_rf_waddr;
                EX_rf_wena <= ID_rf_wena;
                EX_rf_adata <= ID_rf_adata;
                EX_MEM_rf_wena <= ID_MEM_rf_wena;
                EX_suppress_src <= ID_suppress_src;
                EX_pc_setena <= ID_pc_setena;
                EX_pc <= ID_pc;
                EX_MEM_pc_setena <= ID_MEM_pc_setena; 
                EX_mem_addr_src <= ID_mem_addr_src;
                EX_mem_wdata_src <= ID_mem_wdata_src;
                EX_mem_wena <= ID_mem_wena;
                EX_sp_inc <= ID_sp_inc;
                EX_sp_dec <= ID_sp_dec;
                EX_sp_setena <= ID_sp_setena;
                EX_mem_rena <= ID_mem_rena;
                EX_halt <= ID_halt;
                EX_reset <= ID_reset;
                EX_clr <= ID_clr;
            end if;
        end if;
    end process;
end architecture;