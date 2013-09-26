--! @file reset_sequencer_ea.vhd
--! @brief Reset Sequencer for multiple reset signals
--! @author Scott Teal (Scott@Teals.org)
--! @date 2013-09-25

--! Standard IEEE library
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;


--! @brief Reset Sequencer. Sequences reset signals and can check status signals.
--! @details
--! The reset sequencer is used to turn on a system in sequence, with the initial 
--! asynchronous reset signal being debounced and then used to start a sequence 
--! of turning off reset signals. Each signal has a time-out period, after 
--! which it checks to see if the associated "check_good" line is high. If it 
--! is, then the sequencer moves to turning off the next reset signal. If it is 
--! not, then the system brings the reset high again for retry_time before 
--! trying again. If the bit in move_fast associated with the reset signal is 
--! high, then it will move to the next reset signal in sequence immediately 
--! when the associated check_good signal is high.
--!
--! Sequence
--! 1. Come out of reset (rst goes to '0')
--! 2. Set first reset signal (rst_vector(0)) to '0'.
--! 3. If check_good(0) = '1' and move_fast(0) = '1', then repeat from step 2 
--!   with next signal. Else wait for wait_times(0).
--! 4. If check_good(0) = '1', then repeat from step 2 with next signal. Else 
--!   set rst_vector(0) to '1' and wait for retry_time before repeating from 
--!   step 2 with same signal.
--! 5. Sequence complete, set done = '1'


entity reset_sequencer is
  generic (
    clk_period : time := 20 ns; --! Period of clk signal
    --! Vector of times to wait/timeout for each reset signal
    wait_times : time_vector := (others => 160 ns);
    retry_time : time := 80 ns; --! Time to keep reset high while retrying
    move_fast : std_logic_vector; --! If '1',  go to next once check_good = '1'
    debounce_time : time := 1 ms --! Time to wait before rst can change again
  );
  port (
    clk : in std_logic; --! Reference clock
    rst : in std_logic; --! Asynchronous reset
    check_good : in std_logic_vector; --! Signals showing subsystems are ready
    rst_vector : out std_logic_vector; --! Reset signals to subsystems
    done : out std_logic; --! Indicates sequencer is finished
  );
end entity reset_sequencer;

architecture rtl of reset_sequencer is

  function get_count(clk_period, count_time : time) return integer is
  begin
    assert count_time > clk_period
      report "All wait_times must be > clk_period" severity error;
    return (count_time / clk_period) + 1;
  end function;

  function get_counts(clk_period : time,
    count_times : time_vector) return integer is 
    variable counts : integer_vector(count_times'range);
  begin
    for i in count_times'range loop
      counts(i) := get_count(clk_period, count_times);
    end loop;
    return count_times;
  end function;

  function counter_width(count : integer) is
  begin
    return to_integer(ceil(log2(count)));
  end function;

  function counter_widths(counts : integer_vector) is
    variable max_count : integer;
  begin
    max_count := 1;
    for count in counts loop
      max_count := maximum(max_count, count);
    end loop;
    return counter_width(max_count);
  end function;

  constant db_count_val : integer := get_count(clk_period, debounce_time);
  constant db_counter_width : positive := counter_width(db_count_val);
  constant db_counter_init : unsigned((db_count_width - 1) downto 0) :=
    to_unsigned(db_count_val, db_count_width);
  signal debounce_counter : unsigned((db_count_width - 1) downto 0);

begin

end rtl;
