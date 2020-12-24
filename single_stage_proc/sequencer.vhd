-- sequencer.vhd 

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library hproc;
use hproc.hproc_pkg.all;

entity sequencer is
    generic ( G_SIM: integer := 0);
    port (
        aclr : in std_logic;
        sclr : in std_logic;
        clk : in std_logic;
        clk_ena : in std_logic;
        
        rav : in data_t;
        rbv : in data_t;
        
        instr_in : in data_t;
        data_in : in data_t;
        
        rna : out std_logic_vector(3 downto 0);
        rnb : out std_logic_vector(3 downto 0);
        reg_write_addr : out std_logic_vector(3 downto 0);
        reg_write_ena : out std_logic;
        rfsclr : out std_logic;
        
        alu_out : in data_t;
        alu_left : out data_t;
        alu_right : out data_t;
        alu_op : out ALU_OP_SELECT;
        
        code_addr  : out data_t;
        data_addr  : out data_t;
        data_out   : out data_t;
        code_read_ena  : out std_logic;
        data_read_ena  : out std_logic;
        data_write_ena : out std_logic
    );
    
end entity;

architecture rtl of sequencer is 

type seq_state_t is (SEQ_RESET, SEQ_FETCH, SEQ_EXEC, SEQ_MEM_WRITE_REG_A, SEQ_MEM_WRITE_REG_B, SEQ_MEM_WRITE_PC);

signal instr_valid : std_logic;

signal fetch : std_logic;

signal pc, sp : data_t;
signal cur_state, next_state : seq_state_t;
signal inc_pc : std_logic;
signal load_pc : std_logic;
signal pc_loadv : std_logic_vector(15 downto 0);
signal off_pc : std_logic;
signal offsetv : std_logic_vector(11 downto 0);
signal inc_sp : std_logic;
signal dec_sp : std_logic;
signal load_sp : std_logic;
signal sp_loadv : std_logic_vector(15 downto 0);

signal suppress_exec : std_logic;
signal suppress_next : std_logic;

signal set_halted : std_logic;
signal halted : std_logic;

signal instr_int : integer range 0 to 65535;

-- aliased ranges
signal reg_b_addr : std_logic_vector(3 downto 0);
signal reg_a_addr : std_logic_vector(3 downto 0);
signal eight_bit_imm : std_logic_vector(7 downto 0);

begin

instr_int <= to_integer(unsigned(instr_in));
code_read_ena <= fetch;
reg_b_addr <= instr_in(3 downto 0);
reg_a_addr <= instr_in(7 downto 4);
eight_bit_imm <= instr_in(11 downto 4);

reg_halt : process (aclr, clk)
begin
    if (aclr = '1') then
        halted <= '0';
    elsif RISING_EDGE(clk) then
        if (clk_ena = '1') then
            if (sclr = '1') then
                halted <= '0';
            elsif (set_halted = '1') then
                halted <= '1';
            end if;
        end if;
    end if;
            
end process;

reg_pc : process (aclr, clk)
begin     
    if (aclr = '1') then
        pc <= (OTHERS => '0');
    elsif RISING_EDGE(clk) then
        if (clk_ena = '1') then
            if (sclr = '1') then
                pc <= (OTHERS => '0');
            elsif (load_pc = '1') then
                pc <= pc_loadv;
            elsif (off_pc = '1') then
                pc <= std_logic_vector(signed(pc) + signed(offsetv));
            elsif (inc_pc = '1') then
                pc <= std_logic_vector(unsigned(pc) + 1);
            end if;
        end if;
    end if;
            
end process;

reg_sp : process (aclr, clk) 
begin
    if (aclr = '1') then
        sp <= (OTHERS => '1');
    elsif RISING_EDGE(clk) then
        if (clk_ena = '1') then
            if (sclr = '1') then
                sp <= (OTHERS => '1');
            elsif (load_sp = '1') then
                sp <= sp_loadv;
            elsif (dec_sp = '1') then
                sp <= std_logic_vector(unsigned(sp) - 1);
            elsif (inc_sp = '1') then
                sp <= std_logic_vector(unsigned(sp) + 1);
            end if;
        end if;
    end if;
            
end process;

seq_reg : process (aclr, clk)
begin
    if (aclr = '1') then
        cur_state <= SEQ_RESET;
        instr_valid <= '0';
    elsif RISING_EDGE(clk) then
        if (clk_ena = '1') then
            if (sclr = '1') then
                cur_state <= SEQ_RESET;
                instr_valid <= '0';
            else 
                cur_state <= next_state;
                instr_valid <= fetch;
                suppress_exec <= suppress_next;
            end if;
        end if;
    end if;
end process;

seq_com : process(cur_state, 
                  halted, 
						instr_in, instr_int, instr_valid, 
						eight_bit_imm, 
						reg_b_addr, reg_a_addr, 
						rav, rbv, 
						data_in, 
						alu_out, 
						pc, sp, 
						sclr, 
						suppress_exec) 
begin
    next_state <= cur_state;
    set_halted <= '0';
    inc_pc <= '1';
    dec_sp <= '0';
    load_pc <= '0';
	 pc_loadv <= x"0000";
    off_pc <= '0';
    offsetv <= (OTHERS => '0');
    inc_sp <= '0';
    load_sp <= '0';
	 sp_loadv <= x"0000";
    sp_loadv <= (OTHERS => '0');
    rna <= "0000";
    rnb <= "0000";
    reg_write_addr <= "0000";
    reg_write_ena <= '0';
    rfsclr <= sclr;
    alu_left <= (OTHERS => '0');
    alu_right <= (OTHERS => '0');
    alu_op <= OP_NOP;
    fetch <= '1';
    suppress_next <= '0';
    
    code_addr <= pc;
    data_addr <= (OTHERS => '0'); -- this should be 'X'
    data_out  <= (OTHERS => '0'); 
    data_read_ena  <= '0';
    data_write_ena <= '0'; 
    
    case cur_state is
        when SEQ_RESET =>
            inc_pc <= '0';
            fetch <= '0';
            if (halted = '0') then
                next_state <= SEQ_FETCH;
            end if;
        -- in these two, we want to read code mem
        when SEQ_FETCH =>
            next_state <= SEQ_EXEC;
        when SEQ_EXEC =>
            if (suppress_exec = '0' and instr_valid = '1') then
                if (instr_int and 16#c000#) = 0 then 
                    -- store instruction
                    -- b is memory address, a is value
                    rna <= reg_a_addr;
                    rnb <= reg_b_addr;
                    
                    data_out <= rav;
                    data_addr <= std_logic_vector(signed(rbv) + resize(signed(instr_in(13 downto 8)), 16));
                    data_write_ena <= '1';
                elsif (instr_int and 16#c000#) = 16#4000# then
                    -- load instruction
                    -- b is memory address, a is register address (SEQ_MEM_WRITE_REG_A)
                    rnb <= reg_b_addr;
                    rna <= reg_a_addr;
                    
                    data_addr <= std_logic_vector(signed(rbv) + resize(signed(instr_in(13 downto 8)), 16));
                    data_read_ena <= '1';
                    fetch <= '0';
                    inc_pc <= '0';
                    next_state <= SEQ_MEM_WRITE_REG_A;
                elsif (instr_int and 16#7000#) = 0 then
                    -- calli instruction
                    -- sequencer managed
                    data_addr <= sp;
                    dec_sp <= '1';
                    data_out <= pc;
                    data_write_ena <= '1';
                    
                    pc_loadv <= std_logic_vector(signed(pc) + resize(signed(instr_in(11 downto 0)), 16));
                    load_pc <= '1';
                    suppress_next <= '1';
                elsif (instr_int and 16#7000#) = 16#1000# then
                    -- jmpi instruction
                    pc_loadv <= std_logic_vector(signed(pc) + resize(signed(instr_in(11 downto 0)), 16));
                    load_pc <= '1';
                    suppress_next <= '1';
                    
                elsif (instr_int and 16#7000#) = 16#2000# then
                    -- consth instruction
                    rnb <= reg_b_addr;
                    alu_left <= rbv;
                    alu_right <= x"00" & eight_bit_imm;
                    alu_op <= OP_CONSTH;
                    reg_write_addr <= reg_b_addr;
                    reg_write_ena <= '1';
                elsif (instr_int and 16#7000#) = 16#3000# then
                    -- constl instruction
                    alu_left <= x"00" & eight_bit_imm;
                    alu_op <= OP_SIGNEX;
                    reg_write_addr <= reg_b_addr;
                    reg_write_ena <= '1';
                elsif (instr_int and 16#2000#) = 0 then
                    -- pushi instruction
                    data_out <= std_logic_vector(resize(signed(instr_in(12 downto 0)), 16));
                    data_addr <= sp;
                    dec_sp <= '1';
                    data_write_ena <= '1';
                    
                elsif (instr_int and 16#1f00#) = 16#0000# then
                    -- add instruction
                    rna <= reg_a_addr;
                    rnb <= reg_b_addr;
                    alu_left <= rav;
                    alu_right <= rbv;
                    alu_op <= OP_ADD;
                    reg_write_addr <= reg_a_addr;
                    reg_write_ena <= '1';
                    
                elsif (instr_int and 16#1f00#) = 16#0100# then
                    -- sub instruction
                    rna <= reg_a_addr;
                    rnb <= reg_b_addr;
                    alu_left <= rav;
                    alu_right <= rbv;
                    alu_op <= OP_SUB;
                    reg_write_addr <= reg_a_addr;
                    reg_write_ena <= '1';
                    
                elsif (instr_int and 16#1f00#) = 16#0200# then
                    -- and instruction
                    rna <= reg_a_addr;
                    rnb <= reg_b_addr;
                    alu_left <= rav;
                    alu_right <= rbv;
                    alu_op <= OP_AND;
                    reg_write_addr <= reg_a_addr;
                    reg_write_ena <= '1';
                    
                elsif (instr_int and 16#1f00#) = 16#0300# then
                    -- ior instruction
                    rna <= reg_a_addr;
                    rnb <= reg_b_addr;
                    alu_left <= rav;
                    alu_right <= rbv;
                    alu_op <= OP_IOR;
                    reg_write_addr <= reg_a_addr;
                    reg_write_ena <= '1';
                    
                elsif (instr_int and 16#1f00#) = 16#0400# then
                    -- xor instruction
                    rna <= reg_a_addr;
                    rnb <= reg_b_addr;
                    alu_left <= rav;
                    alu_right <= rbv;
                    alu_op <= OP_XOR;
                    reg_write_addr <= reg_a_addr;
                    reg_write_ena <= '1';
                    
                elsif (instr_int and 16#1f00#) = 16#0500# then
                    -- logical shift l instruction
                    rna <= reg_a_addr;
                    rnb <= reg_b_addr;
                    alu_left <= rav;
                    alu_right <= rbv;
                    alu_op <= OP_LSL;
                    reg_write_addr <= reg_a_addr;
                    reg_write_ena <= '1';
                    
                elsif (instr_int and 16#1f00#) = 16#0600# then
                    -- arithmetic shift r instruction
                    rna <= reg_a_addr;
                    rnb <= reg_b_addr;
                    alu_left <= rav;
                    alu_right <= rbv;
                    alu_op <= OP_ASR;
                    reg_write_addr <= reg_a_addr;
                    reg_write_ena <= '1';
                    
                elsif (instr_int and 16#1f00#) = 16#0700# then
                    -- logical shift r instruction
                    rna <= reg_a_addr;
                    rnb <= reg_b_addr;
                    alu_left <= rav;
                    alu_right <= rbv;
                    alu_op <= OP_LSR;
                    reg_write_addr <= reg_a_addr;
                    reg_write_ena <= '1';
                    
                elsif (instr_int and 16#1f00#) = 16#0800# then
                    -- multiply, store the l bits instruction
                    rna <= reg_a_addr;
                    rnb <= reg_b_addr;
                    alu_left <= rav;
                    alu_right <= rbv;
                    alu_op <= OP_MULTL;
                    reg_write_addr <= reg_a_addr;
                    reg_write_ena <= '1';
                    
                elsif (instr_int and 16#1f00#) = 16#0900# then
                    -- multiply, store the h bits instruction
                    rna <= reg_a_addr;
                    rnb <= reg_b_addr;
                    alu_left <= rav;
                    alu_right <= rbv;
                    alu_op <= OP_MULTH;
                    reg_write_addr <= reg_a_addr;
                    reg_write_ena <= '1';
                    
                elsif (instr_int and 16#1f00#) = 16#0a00# then
                    -- move instruction
                    rnb <= reg_b_addr;
                    alu_left <= rbv;
                    alu_op <= OP_CP;
                    reg_write_addr <= reg_a_addr;
                    reg_write_ena <= '1';
                    
                elsif (instr_int and 16#0f00#) = 0 then
                    -- skip less than instruction
                    rnb <= reg_b_addr;
                    rna <= reg_a_addr;
                    alu_left <= rav;
                    alu_right <= rbv;
                    alu_op <= OP_LT;
                    suppress_next <= alu_out(0);
                    
                elsif (instr_int and 16#0f00#) = 16#0100# then
                    -- skip greater than instruction
                    rnb <= reg_b_addr;
                    rna <= reg_a_addr;
                    alu_left <= rav;
                    alu_right <= rbv;
                    alu_op <= OP_GT;
                    suppress_next <= alu_out(0);
                    
                elsif (instr_int and 16#0f00#) = 16#0200# then
                    -- skip less than or equal to instruction
                    rnb <= reg_b_addr;
                    rna <= reg_a_addr;
                    alu_left <= rav;
                    alu_right <= rbv;
                    alu_op <= OP_LE;
                    suppress_next <= alu_out(0);
                    
                elsif (instr_int and 16#0f00#) = 16#0300# then
                    -- skip greater than or equal to instruction
                    rnb <= reg_b_addr;
                    rna <= reg_a_addr;
                    alu_left <= rav;
                    alu_right <= rbv;
                    alu_op <= OP_GE;
                    suppress_next <= alu_out(0);
                    
                elsif (instr_int and 16#0f00#) = 16#0400# then
                    -- skip equal to instruction
                    rnb <= reg_b_addr;
                    rna <= reg_a_addr;
                    alu_left <= rav;
                    alu_right <= rbv;
                    alu_op <= OP_EQ;
                    suppress_next <= alu_out(0);
                    
                elsif (instr_int and 16#0f00#) = 16#0500# then
                    -- skip not equal instruction
                    rnb <= reg_b_addr;
                    rna <= reg_a_addr;
                    alu_left <= rav;
                    alu_right <= rbv;
                    alu_op <= OP_NE;
                    suppress_next <= alu_out(0);
                    
                elsif (instr_int and 16#07f0#) = 0 then
                    -- inc instruction
                    rnb <= reg_b_addr;
                    
                    alu_left <= rbv;
                    alu_op <= OP_INC;
                    
                    reg_write_addr <= reg_b_addr;
                    reg_write_ena <= '1';
                    
                elsif (instr_int and 16#07f0#) = 16#0010# then
                    -- dec instruction
                    rnb <= reg_b_addr;
                    
                    alu_left <= rbv;
                    alu_op <= OP_DEC;
                    
                    reg_write_addr <= reg_b_addr;
                    reg_write_ena <= '1';
                    
                elsif (instr_int and 16#07f0#) = 16#0020# then
                    -- negate instruction
                    rnb <= reg_b_addr;
                    
                    alu_left <= rbv;
                    alu_op <= OP_NEG;
                    
                    reg_write_addr <= reg_b_addr;
                    reg_write_ena <= '1';
                    
                elsif (instr_int and 16#07f0#) = 16#0030# then
                    -- complement instruction
                    rnb <= reg_b_addr;
                    
                    alu_left <= rbv;
                    alu_op <= OP_COM;
                    
                    reg_write_addr <= reg_b_addr;
                    reg_write_ena <= '1';
                    
                elsif (instr_int and 16#07f0#) = 16#0040# then
                    -- call register instruction
                    data_addr <= sp;
                    dec_sp <= '1';
                    data_out <= pc;
                    data_write_ena <= '1';
                    
                    rnb <= reg_b_addr;
                    pc_loadv <= rbv;
                    load_pc <= '1';
                    suppress_next <= '1';
                    
                elsif (instr_int and 16#07f0#) = 16#0050# then
                    -- jump to register instruction
                    rnb <= reg_b_addr;
                    pc_loadv <= rbv;
                    load_pc <= '1';
                    suppress_next <= '1';
                    
                elsif (instr_int and 16#07f0#) = 16#0060# then
                    -- move reg into sp instruction
                    rnb <= reg_b_addr;
                    sp_loadv <= rbv;
                    load_sp <= '1';
                    
                elsif (instr_int and 16#07f0#) = 16#0070# then
                    -- move sp into reg instruction
                    alu_left <= sp;
                    alu_op <= OP_CP;
                    
                    reg_write_addr <= reg_b_addr;
                    reg_write_ena <= '1';
                    
                elsif (instr_int and 16#07f0#) = 16#0080# then
                    -- push reg onto stack instruction
                    rnb <= reg_b_addr;
                    data_write_ena <= '1';
                    data_addr <= sp;
                    data_out <= rbv;
                    dec_sp <= '1';
                    
                elsif (instr_int and 16#07f0#) = 16#0090# then
                    -- pop last on stack into reg
                    data_read_ena <= '1';
                    data_addr <= std_logic_vector(unsigned(sp) + 1);
                    inc_sp <= '1';
                    next_state <= SEQ_MEM_WRITE_REG_B;
                    fetch <= '0';
                    inc_pc <= '0';
                elsif (instr_int and 16#03f0#) = 0 then
                    -- skip zero instruction
                    rnb <= reg_b_addr;
                    alu_left <= rbv;
                    alu_op <= OP_Z;
                    suppress_next <= alu_out(0);
                    
                elsif (instr_int and 16#03f0#) = 16#0010# then
                    -- skip not zero instruction
                    rnb <= reg_b_addr;
                    alu_left <= rbv;
                    alu_op <= OP_NZ;
                    suppress_next <= alu_out(0);
                    
                elsif (instr_int and 16#03f0#) = 16#0020# then
                    -- skip minus instruction
                    rnb <= reg_b_addr;
                    alu_left <= rbv;
                    alu_op <= OP_MI;
                    suppress_next <= alu_out(0);
                    
                elsif (instr_int and 16#03f0#) = 16#0030# then
                    -- skip plus instruction
                    rnb <= reg_b_addr;
                    alu_left <= rbv;
                    alu_op <= OP_PL;
                    suppress_next <= alu_out(0);
                    
                elsif instr_int = 16#fe00# then
                    -- halt instruction
                    set_halted <= '1';
                    inc_pc <= '0';
                    fetch <= '0';
                    next_state <= SEQ_RESET;
                    
                elsif instr_int = 16#fe01# then
                    -- reset instruction
                    next_state <= SEQ_RESET;
                    load_pc <= '1';
                    pc_loadv <= x"0000";
                    load_sp <= '1';
                    sp_loadv <= x"ffff";
                    
                elsif instr_int = 16#fe02# then
                    -- return instruction
                    -- note, this returns from exactly one (the most recent) call.
                     inc_sp <= '1';
                     data_addr <= std_logic_vector(unsigned(sp) + 1);
                     data_read_ena <= '1';
                     next_state <= SEQ_MEM_WRITE_PC;
                     
                elsif instr_int = 16#fe03# then
                    -- clr instruction
                    rfsclr <= '1';
                -- sys instructions
                elsif (instr_int and 16#ff00#) = 16#ff00# then
                    -- rna happens to be the right 4 bits. IT IS NOT A REGISTER HERE!
                    null; 
                end if;
            end if;

        when SEQ_MEM_WRITE_REG_B =>
            alu_left <= data_in;
            alu_op <= OP_CP;
            reg_write_ena <= '1';
            reg_write_addr <= reg_b_addr;
            next_state <= SEQ_EXEC;
            
        when SEQ_MEM_WRITE_REG_A =>
            alu_left <= data_in;
            alu_op <= OP_CP;
            reg_write_ena <= '1';
            reg_write_addr <= reg_a_addr;
            next_state <= SEQ_EXEC;
            
        when SEQ_MEM_WRITE_PC =>
            load_pc <= '1';
            pc_loadv <= data_in;
            suppress_next <= '1';
            next_state <= SEQ_EXEC;
            
        when OTHERS =>
            next_state <= SEQ_RESET;
        end case;
end process;

end rtl;
