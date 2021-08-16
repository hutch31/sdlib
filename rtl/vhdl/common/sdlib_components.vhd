library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.ALL;
use work.architecture_types.ALL;

package sdlib_components is

component sd_pulse_sync is
  port (
    clk_in    : in std_logic;
    reset_in  : in std_logic;
    pulse_in : in std_logic;

    clk_out : in std_logic;
    reset_out : in std_logic;
    pulse_out : out std_logic
  );
end component;

component sd_fifo_s is
  generic (
    width : integer := 8;
    depth : integer := 16;
    async : integer := 0;
    asz   : integer := 4
  );
  port
    (
     c_clk : in std_logic;
     c_reset: in std_logic;
     c_srdy: in std_logic;
     c_drdy: out std_logic;
     c_data : in std_logic_vector(width-1 downto 0);
     c_usage : out std_logic_vector(asz downto 0);

     p_clk: in std_logic;
     p_reset: in std_logic;
     p_srdy : out std_logic;
     p_drdy: in std_logic;
     p_data: out std_logic_vector(width-1 downto 0);
     p_usage : out std_logic_vector(asz downto 0)
   );
end component;

component sd_fifo_c is
  generic (
    width : integer := 8;
    depth : integer := 16;
    usz   : integer := 5    -- Needs to be number of bits for depth + 1
  );
  port
    (
     clk : in std_logic;
     reset: in std_logic;
     c_srdy: in std_logic;
     c_drdy: out std_logic;
     c_data : in std_logic_vector(width-1 downto 0);
     usage : out std_logic_vector(usz-1 downto 0);

     p_srdy : out std_logic;
     p_drdy: in std_logic;
     p_data: out std_logic_vector(width-1 downto 0)
   );
end component;

component sd_sync2 is
  generic (
    width : integer := 1
  );
 port (
   clk : in std_logic;
   sync_in : in std_logic_vector(width-1 downto 0);
   sync_out : out std_logic_vector(width-1 downto 0)
 );
end component;

end package sdlib_components;
