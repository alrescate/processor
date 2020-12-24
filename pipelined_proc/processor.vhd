-- processor.vhd 

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library pipe_proc;
use pipe_proc.pipe_proc_pkg.all;

entity processor is
    generic ( G_SIM: integer := 0);
    port (
        aclr : in std_logic;
        sclr : in std_logic;
        clk : in std_logic;
        
        data_addr : out std_logic_vector(15 downto 0);

        data_write_ena : out std_logic;
        data_write_data : out std_logic_vector(15 downto 0);

        data_read_ena : out std_logic;
        data_read_data : in std_logic_vector(15 downto 0);
        
        code_addr : out std_logic_vector(15 downto 0);

        code_read_ena : out std_logic;
        code_read_data : in std_logic_vector(15 downto 0);
        
        sys_out : out data_t;
        sys_imm : out std_logic_vector(3 downto 0)
    );
    
end entity;
    
architecture rtl of processor is 

signal fce : std_logic;
signal fpcse : std_logic;
signal fpcsv : data_t;
signal fvin : std_logic;
signal IF_valid : std_logic;
signal IF_instr : data_t;
signal IF_pc : data_t;
signal rfsclr : std_logic;
signal rf_wena : std_logic;
signal rf_waddr : std_logic_vector(3 downto 0);
signal rf_wdata : data_t;
signal rf_wena2 : std_logic;
signal rf_waddr2 : std_logic_vector(3 downto 0);
signal rf_wdata2 : data_t;
signal rna : std_logic_vector(3 downto 0);
signal rnb : std_logic_vector(3 downto 0);
signal rav : data_t;
signal rbv : data_t;
signal rfa_matters : std_logic;
signal rfb_matters : std_logic;
signal sp : data_t;
signal read_sp : std_logic;
signal dvin : std_logic;
signal ID_valid : std_logic;
signal ID_ALU_op : ALU_OP_SELECT;
signal ID_ALU_left : data_t;
signal ID_ALU_right : data_t;
signal ID_rf_waddr : std_logic_vector(3 downto 0);
signal ID_rf_wena : std_logic;
signal ID_rf_adata : data_t;
signal ID_MEM_rf_wena : std_logic;
signal ID_suppress_src : std_logic_vector(1 downto 0);
signal ID_pc_setena : std_logic;
signal ID_pc_out : data_t;
signal ID_MEM_pc_setena : std_logic;
signal ID_mem_addr_src : std_logic;
signal ID_mem_wdata_src : std_logic_vector(1 downto 0);
signal ID_mem_wena : std_logic;
signal ID_sp_inc : std_logic;
signal ID_sp_dec : std_logic;
signal ID_sp_setena : std_logic;
signal ID_mem_rena : std_logic;
signal ID_halt : std_logic;
signal ID_reset : std_logic;
signal ID_clr : std_logic;
signal alu_out : data_t;
signal evin : std_logic;
signal EX_valid : std_logic;
signal EX_ALU_result : data_t;
signal EX_rf_waddr : std_logic_vector(3 downto 0);
signal EX_rf_wena : std_logic;
signal EX_rf_adata : data_t;
signal EX_MEM_rf_wena : std_logic;
signal EX_suppress_src : std_logic_vector(1 downto 0);
signal EX_pc_setena : std_logic;
signal EX_pc : data_t;
signal EX_MEM_pc_setena : std_logic; 
signal EX_mem_addr_src : std_logic;
signal EX_mem_wdata_src : std_logic_vector(1 downto 0);
signal EX_mem_wena : std_logic;
signal EX_sp_inc : std_logic;
signal EX_sp_dec : std_logic;
signal EX_sp_setena : std_logic;
signal EX_mem_rena : std_logic;
signal EX_halt : std_logic;
signal EX_reset : std_logic;
signal EX_clr : std_logic;
signal suppress_wbvin : std_logic;
signal wbvin : std_logic;
signal suppress : std_logic;
signal suppress_set : std_logic;
signal suppress_sclr : std_logic;
signal sp_inc : std_logic; 
signal sp_dec : std_logic;
signal sp_setv : data_t;
signal sp_setena : std_logic;
signal halt : std_logic;
signal reset : std_logic;
signal MEM_valid : std_logic;
signal MEM_rf_wena : std_logic;
signal MEM_rf_waddr : std_logic_vector(3 downto 0);
signal MEM_pc_setena : std_logic;
signal inv_IF_z : std_logic;
signal invalidate_IF : std_logic;

signal data_stall : std_logic;
signal data_dvin : std_logic;

signal sys : data_t;

signal p4_branch : std_logic;
signal p5_branch : std_logic;

signal control_halt : std_logic;

signal halted : std_logic;

signal data_stall_1 : std_logic;
signal data_stall_2 : std_logic;
signal data_stall_3 : std_logic;
signal data_stall_4 : std_logic;
signal data_stall_5 : std_logic;

signal sclr_z : std_logic;

begin

sys_out <= sys;

code_read_ena <= fce; -- these are the same thing - not clk_ena for fetch, no read in code

reg_sp : process(clk, aclr)
begin
    if (aclr = '1') then
        sp <= x"ffff";
    elsif RISING_EDGE(clk) then
        if (sclr = '1') then
            sp <= x"ffff";
        elsif (sp_setena = '1') then
            sp <= sp_setv;
        elsif (sp_inc = '1') then
            sp <= std_logic_vector(unsigned(sp) + 1);
        elsif (sp_dec = '1') then
            sp <= std_logic_vector(unsigned(sp) - 1);
        end if;
    end if;
end process;

reg_suppress : process(clk, aclr)
begin
    if (aclr = '1') then
        suppress <= '0';
    elsif RISING_EDGE(clk) then
        if (suppress_sclr = '1') then
            suppress <= '0';
        elsif (suppress_set = '1') then
            suppress <= '1';
        end if;
    end if;
end process;

com_suppress : process(EX_valid, suppress)
begin
    if ((EX_valid = '1') and (suppress = '1')) then
        suppress_wbvin <= '1';
        suppress_sclr <= '1';
    else
        suppress_wbvin <= '0';
        suppress_sclr <= '0';
    end if;
end process;

-- this should detect 4th- and 5th-stage branches and request the appropriate
-- changes to the control signals. reset acts as a 4th-stage branch. 
p4_branch <= '1' when (((EX_pc_setena = '1') or (reset = '1')) and (wbvin = '1')) else '0';
p5_branch <= '1' when ((MEM_pc_setena = '1') and (MEM_valid = '1')) else '0';
inv_IF_z <= '1' when ((p4_branch or p5_branch) = '1') else '0'; 

reg_invalidate : process(clk, aclr)
begin
    if (aclr = '1') then
        invalidate_IF <= '0';
    elsif RISING_EDGE(clk) then
        invalidate_IF <= inv_IF_z;
    end if;
end process;

-- reg_data_stall : process(aclr, clk) 
-- begin
--     if (aclr = '1') then
--         data_stall <= '0';
--     elsif RISING_EDGE(clk) then
--         data_stall <= '0';
--         if (rfa_matters = '1') then
--             if ((rna = ID_rf_waddr)   and (ID_valid = '1'))   or 
--                ((rna = EX_rf_waddr)   and (EX_valid = '1'))   or 
--                ((rna = MEM_rf_waddr) and (MEM_valid = '1') and (MEM_rf_wena = '1')) or -- this is because MEM doesn't get its own unique waddr
--                ((ID_clr = '1')        and (ID_valid = '1'))   or 
--                ((EX_clr = '1')        and (EX_valid = '1'))   then
--                 data_stall <= '1';
--             end if;
--         end if;
--         if (rfb_matters = '1') then
--             if ((rnb = ID_rf_waddr)   and (ID_valid = '1'))   or 
--                ((rnb = EX_rf_waddr)   and (EX_valid = '1'))   or 
--                ((rnb = MEM_rf_waddr) and (MEM_valid = '1') and (MEM_rf_wena = '1')) or
--                ((ID_clr = '1')        and (ID_valid = '1'))   or 
--                ((EX_clr = '1')        and (EX_valid = '1'))   then
--                 data_stall <= '1';
--             end if;
--         end if;
--         if (read_sp = '1') then
--             if (((ID_sp_inc = '1') or (ID_sp_dec = '1') or (ID_sp_setena = '1')) and (ID_valid = '1')) or 
--                (((EX_sp_inc = '1') or (EX_sp_dec = '1') or (EX_sp_setena = '1')) and (EX_valid = '1')) then
--                 data_stall <= '1';
--             end if;
--         end if;
--     end if;
-- end process;

com_data_stall : process(rfa_matters, rfb_matters, 
                         rna, rnb,
                         ID_rf_waddr, ID_valid, 
                         EX_rf_waddr, EX_valid,
                         MEM_rf_waddr, MEM_valid, MEM_rf_wena,
                         read_sp, ID_sp_inc, ID_sp_dec, ID_sp_setena,
                         EX_sp_inc, EX_sp_dec, EX_sp_setena,
                         ID_clr, EX_clr)
begin
    data_stall <= '0';
    if (rfa_matters = '1') then
        if ((rna = ID_rf_waddr)   and (ID_valid = '1'))   or 
           ((rna = EX_rf_waddr)   and (EX_valid = '1'))   or 
           ((rna = MEM_rf_waddr) and (MEM_valid = '1') and (MEM_rf_wena = '1')) or -- this is because MEM doesn't get its own unique waddr
           ((ID_clr = '1')        and (ID_valid = '1'))   or 
           ((EX_clr = '1')        and (EX_valid = '1'))   then
            data_stall <= '1';
        end if;
    end if;
    if (rfb_matters = '1') then
        if ((rnb = ID_rf_waddr)   and (ID_valid = '1'))   or 
           ((rnb = EX_rf_waddr)   and (EX_valid = '1'))   or 
           ((rnb = MEM_rf_waddr) and (MEM_valid = '1') and (MEM_rf_wena = '1')) or
           ((ID_clr = '1')        and (ID_valid = '1'))   or 
           ((EX_clr = '1')        and (EX_valid = '1'))   then
            data_stall <= '1';
        end if;
    end if;
    if (read_sp = '1') then
        if (((ID_sp_inc = '1') or (ID_sp_dec = '1') or (ID_sp_setena = '1')) and (ID_valid = '1')) or 
           (((EX_sp_inc = '1') or (EX_sp_dec = '1') or (EX_sp_setena = '1')) and (EX_valid = '1')) then
            data_stall <= '1';
        end if;
    end if;
end process;

reg_sclr : process(clk, aclr)
begin
    if (aclr = '1') then
        sclr_z <= '1';
    elsif RISING_EDGE(clk) then
        sclr_z <= sclr;
    end if;
end process;

-- halt is a different mechanism, which cannot coincide with p4 branches and which is
-- subordinate to p5 branches
control_halt <= '1' when ((halt = '1') and (wbvin = '1')) else '0';

-- alright, time to actually drive control signals

-- fetch gets its clk_ena unless we have a p5 branch, a p4 branch, or a data stall
fce <= '0' when (((p5_branch = '1') or (p4_branch = '1') or (data_stall = '1')) or (halted = '1')) else '1';

-- fetch gets its valid unless we have a p5 branch, a p4 branch, or a delayed invalidate
fvin <= '0' when (((p5_branch = '1') or (p4_branch = '1') or (invalidate_IF = '1')) or (halted = '1') or (sclr_z = '1')) else '1';

-- decode gets its valid unless we have a p5 branch, a p4 branch, or a data stall
dvin <= '0' when (((p5_branch = '1') or (p4_branch = '1') or (data_stall = '1')) or (halted = '1')) else IF_valid;

-- execute gets its valid unless we have a p5 or p4 branch
evin <= '0' when (((p5_branch = '1') or (p4_branch = '1')) or (halted = '1')) else ID_valid;

-- first wb gets its valid unless we have a p5 branch or a skip pending
wbvin <= '0' when (((p5_branch = '1') or (suppress_wbvin = '1')) or (halted = '1')) else EX_valid;

reg_halted : process(clk, aclr)
begin
    if (aclr = '1') then
        halted <= '0';
    elsif RISING_EDGE(clk) then
        if (sclr = '1') then
            halted <= '0';
        elsif (control_halt = '1') then
            halted <= '1';
        end if;
    end if;
end process;

u_fetch : entity pipe_proc.fetch
    generic map ( G_SIM => G_SIM)
    port map (
        aclr => aclr,
        sclr => sclr,
        clk => clk,
        clk_ena => fce,
        
        instr_in => code_read_data,
        pc_setena => fpcse,
        pc_setv => fpcsv,
        
        valid_in => fvin,
        
        code_addr => code_addr,
        
        IF_valid => IF_valid,
        IF_instr => IF_instr,
        IF_pc => IF_pc
    );
    
u_register_file : entity pipe_proc.register_file
    generic map ( G_SIM => G_SIM)
    port map (
        aclr => aclr,
        sclr => rfsclr,
        clk => clk,
        clk_ena => '1', -- I have some suspicions about this
        write_ena => rf_wena,
        write_addr => rf_waddr,
        writev => rf_wdata,
        write_ena2 => rf_wena2,
        write_addr2 => rf_waddr2,
        writev2 => rf_wdata2,
        rna => rna,
        rnb => rnb,
        
        rav_out => rav,
        rbv_out => rbv
    );
    
u_decode : entity pipe_proc.decode
    generic map ( G_SIM => G_SIM)
    port map (
        aclr => aclr,
        sclr => sclr,
        clk => clk,
        clk_ena => '1', -- there should be no reason to challenge the decode clk_ena
        
        IF_pc => IF_pc,
        IF_instr => IF_instr,
        
        rf_raddrA => rna,
        rf_raddrB => rnb,
        
        -- the subject of read-before-write hazards
        rf_adata => rav,
        rf_bdata => rbv,
        
        rfa_matters => rfa_matters,
        rfb_matters => rfb_matters,
         
        valid_in => dvin,
        
        sp => sp,
        
        read_sp => read_sp,
        
        ID_valid => ID_valid,
        ID_ALU_op => ID_ALU_op, 
        ID_ALU_left => ID_ALU_left,
        ID_ALU_right => ID_ALU_right,
        ID_rf_waddr => ID_rf_waddr,
        ID_rf_wena => ID_rf_wena,
        ID_rf_adata => ID_rf_adata,
        ID_MEM_rf_wena => ID_MEM_rf_wena,
        ID_suppress_src => ID_suppress_src,
        ID_pc_setena => ID_pc_setena,
        ID_pc_out => ID_pc_out,
        ID_MEM_pc_setena => ID_MEM_pc_setena,  
        ID_mem_addr_src => ID_mem_addr_src,
        ID_mem_wdata_src => ID_mem_wdata_src,
        ID_mem_wena => ID_mem_wena,
        ID_sp_inc => ID_sp_inc,
        ID_sp_dec => ID_sp_dec,
        ID_sp_setena => ID_sp_setena,
        ID_mem_rena => ID_mem_rena,
        ID_halt => ID_halt,
        ID_reset => ID_reset,
        ID_clr => ID_clr,
        
        sys_out => sys,
        sys_imm => sys_imm
    );

u_alu : entity pipe_proc.alu
    generic map ( G_SIM => G_SIM)
    port map (
        left_v => ID_ALU_left,
        right_v => ID_ALU_right,
        alu_select => ID_ALU_op,
        
        alu_out => alu_out
    );
    
u_execute : entity pipe_proc.execute
    generic map ( G_SIM => G_SIM)
    port map (
        aclr => aclr,
        sclr => sclr,
        clk => clk,
        clk_ena => '1', -- there should be no reason to challenge the execute clk_ena
         
        ID_valid => evin,
        ALU_result_in => alu_out,
        ID_rf_waddr => ID_rf_waddr,
        ID_rf_wena => ID_rf_wena,
        ID_rf_adata => ID_rf_adata,
        ID_MEM_rf_wena => ID_MEM_rf_wena,
        ID_suppress_src =>ID_suppress_src,
        ID_pc_setena => ID_pc_setena,
        ID_pc => ID_pc_out,
        ID_MEM_pc_setena => ID_MEM_pc_setena,
        ID_mem_addr_src => ID_mem_addr_src,
        ID_mem_wdata_src => ID_mem_wdata_src,
        ID_mem_wena => ID_mem_wena,
        ID_sp_inc => ID_sp_inc,
        ID_sp_dec => ID_sp_dec,
        ID_sp_setena => ID_sp_setena,
        ID_mem_rena => ID_mem_rena,
        ID_halt => ID_halt,
        ID_reset => ID_reset,
        ID_clr => ID_clr,
        
        EX_valid => EX_valid,
        EX_ALU_result => EX_ALU_result,
        EX_rf_waddr => EX_rf_waddr,
        EX_rf_wena => EX_rf_wena,
        EX_rf_adata => EX_rf_adata,
        EX_MEM_rf_wena => EX_MEM_rf_wena,
        EX_suppress_src => EX_suppress_src,
        EX_pc_setena => EX_pc_setena,
        EX_pc => EX_pc,
        EX_MEM_pc_setena => EX_MEM_pc_setena,
        EX_mem_addr_src => EX_mem_addr_src,
        EX_mem_wdata_src => EX_mem_wdata_src,
        EX_mem_wena => EX_mem_wena,
        EX_sp_inc => EX_sp_inc,
        EX_sp_dec => EX_sp_dec,
        EX_sp_setena => EX_sp_setena,
        EX_mem_rena => EX_mem_rena,
        EX_halt => EX_halt,
        EX_reset => EX_reset,
        EX_clr => EX_clr
    );
    
u_first_wb : entity pipe_proc.first_wb
    generic map ( G_SIM => G_SIM)
    port map (
        aclr => aclr,
        sclr => sclr,
        clk => clk,
        clk_ena => '1', -- there should be no reason to challenge this
         
        EX_valid => wbvin,
        EX_ALU_out => EX_ALU_result,
        EX_rf_waddr => EX_rf_waddr,
        EX_rf_wena => EX_rf_wena,
        EX_rf_adata => EX_rf_adata,
        EX_MEM_rf_wena => EX_MEM_rf_wena,
        EX_suppress_src => EX_suppress_src,
        EX_pc_setena => EX_pc_setena,
        EX_pc => EX_pc,
        EX_MEM_pc_setena => EX_MEM_pc_setena,
        EX_mem_addr_src => EX_mem_addr_src,
        EX_mem_wdata_src => EX_mem_wdata_src,
        EX_mem_wena => EX_mem_wena,                                                           
        EX_sp_inc => EX_sp_inc,
        EX_sp_dec => EX_sp_dec,
        EX_sp_setena => EX_sp_setena,
        EX_mem_rena => EX_mem_rena,
        EX_halt => EX_halt,
        EX_reset => EX_reset,
        EX_clr => EX_clr,
        
        mem_rdata => data_read_data,
        sp => sp,
        
        WB_rf_wdata => rf_wdata, 
        WB_rf_waddr => rf_waddr,
        WB_rf_wena => rf_wena,
        WB_rf_wdata2 => rf_wdata2, 
        WB_rf_waddr2 => rf_waddr2,
        WB_rf_wena2 => rf_wena2,
        WB_suppress => suppress_set,
        WB_pc_setv => fpcsv,
        WB_pc_setena => fpcse,
        WB_mem_addr => data_addr,
        WB_mem_wdata => data_write_data,
        WB_mem_wena => data_write_ena,
        WB_sp_inc => sp_inc,
        WB_sp_dec => sp_dec,
        WB_sp_setv => sp_setv,
        WB_sp_setena => sp_setena,
        WB_mem_rena => data_read_ena,
        WB_halt => halt,
        WB_reset => reset,
        WB_clr => rfsclr,
        
        MEM_valid_out => MEM_valid,
        MEM_rf_waddr_out => MEM_rf_waddr,
        MEM_rf_wena_out => MEM_rf_wena,
        MEM_pc_setena_out => MEM_pc_setena
    );
    
end rtl;
