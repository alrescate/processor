library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library std;
use std.textio.all;

library hproc;

package hproc_pkg is

Type ALU_OP_SELECT is   (OP_ADD,    OP_SUB, 
                         OP_INC,    OP_DEC, 
                         OP_AND, 
                         OP_IOR,    OP_XOR, 
                         OP_ASR,    OP_LSR,    OP_LSL,
                         OP_MULTL,  OP_MULTH, 
                         OP_LT,     OP_LE,     OP_GT,     OP_GE,    
                         OP_EQ,     OP_NE,
                         OP_NEG,    OP_COM,
                         OP_Z,      OP_NZ,     OP_MI,     OP_PL,
                         OP_NOP,    OP_CP,
                         OP_SIGNEX, OP_CONSTH);
                         
subtype data_t is std_logic_vector(15 downto 0);
type data_array_t is array(0 to 15) of data_t;
 
constant ALU_TRUE : std_logic_vector(15 downto 0) := x"ffff";
constant ALU_FALSE : std_logic_vector(15 downto 0) := x"0000";

function "and"(a : integer; b : integer) return integer;

end package;

package body hproc_pkg is

  function "and"(a : integer; b : integer) return integer is
    variable tempa, tempb : unsigned(15 downto 0);
  begin
    tempa := to_unsigned(a, 16);
    tempb := to_unsigned(b, 16);
    return to_integer(unsigned(std_logic_vector(tempa) and std_logic_vector(tempb)));
  end;

end package body hproc_pkg;

