--! @file reset_sequencer_ea.vhd
--! @brief Reset Sequencer for multiple reset signals
--! @author Scott Teal (Scott@Teals.org)
--! @date 2013-09-25
--! @copyright
--! Copyright 2013 Richard Scott Teal, Jr.
--! 
--! Licensed under the Apache License, Version 2.0 (the "License"); you may not 
--! use this file except in compliance with the License. You may obtain a copy 
--! of the License at
--! 
--! http://www.apache.org/licenses/LICENSE-2.0
--! 
--! Unless required by applicable law or agreed to in writing, software 
--! distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
--! WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
--! License for the specific language governing permissions and limitations
--! under the License.


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
    wait_times : time_vector;
    retry_time : time := 80 ns; --! Time to keep reset high while retrying
    move_fast : std_logic_vector; --! If '1',  go to next once check_good = '1'
    debounce_time : time := 1 ms --! Time to wait before rst can change again
  );
  port (
    clk : in std_logic; --! Reference clock
    rst : in std_logic; --! Asynchronous reset
    check_good : in std_logic_vector; --! Signals showing subsystems are ready
    rst_vector : out std_logic_vector; --! Reset signals to subsystems
    done : out std_logic --! Indicates sequencer is finished
  );
end entity reset_sequencer;

architecture rtl of reset_sequencer is

  type unsigned_vector is array(natural range <>) of unsigned;

  function get_count(clk_period, count_time : time) return integer is
  begin
    assert count_time > clk_period
      report "All wait_times must be > clk_period" severity error;
    return (count_time / clk_period) + 1;
  end function;

  function get_counts(clk_period : time;
    count_times : time_vector) return integer_vector is 
    variable counts : integer_vector(count_times'range);
  begin
    for i in count_times'range loop
      counts(i) := get_count(clk_period, count_times(i));
    end loop;
    return counts;
  end function;

  function counter_width(count : integer) return integer is
  begin
    return integer(ceil(log2(real(count))));
  end function;

  function counter_widths(counts : integer_vector) return integer is
    variable max_count : integer;
  begin
    max_count := 1;
    for i in counts'range loop
      max_count := maximum(max_count, counts(i));
    end loop;
    return counter_width(max_count);
  end function;

  function to_unsigned_vector(vals : integer_vector; width : positive)
    return unsigned_vector is
    variable unsigneds : unsigned_vector(vals'range)((width - 1) downto 0);
  begin
    for i in vals'range loop
      unsigneds(i) := to_unsigned(vals(i), width);
    end loop;
    return unsigneds;
  end function;

  -- Debounce Counter Constants and signals
  --! Value debounce counter will count down from
  constant db_count_val : integer := get_count(clk_period, debounce_time);
  --! Minimum possible width of debounce counter
  constant db_counter_width : positive := counter_width(db_count_val);
  --! Unsigned type value of db_count_val
  constant db_counter_init : unsigned((db_counter_width - 1) downto 0) :=
    to_unsigned(db_count_val, db_counter_width);
  --! Debounce Counter register
  signal debounce_counter : unsigned((db_counter_width - 1) downto 0);

  -- Timer constants and signals
  --! Values timer counter will count down from during sequencing
  constant timer_vals : integer_vector := get_counts(clk_period, wait_times);
  --! Value timer counter will count down from when retrying
  constant retry_val : integer := get_count(clk_period, retry_time);
  --! Minimum possible width of timer counter register
  constant timer_width : positive := counter_widths(timer_vals & retry_val);
  --! Unsigned type value of retry_val
  constant retry_init : unsigned((timer_width - 1) downto 0) :=
    to_unsigned(retry_val, timer_width);
  --! Unsigned type values of timer_vals
  constant timer_inits : unsigned_vector
    (timer_vals'range)((timer_width - 1) downto 0) :=
    to_unsigned_vector(timer_vals, timer_width);
  --! Timer Register
  signal timer : unsigned((timer_width - 1) downto 0);

  --! rst synchronized to clk and debounced
  signal sync_rst : std_logic;
  
  constant reset_width : positive := counter_width(rst_vector'length);
  --! Record current location in reset sequence
  signal reset_stage : unsigned((reset_width - 1) downto 0);

  --! Indicates if currently retrying a reset.
  signal retry : std_logic;

  
begin
  -- Verify all vectors are of equal length, otherwise the reset sequencer will 
  -- act in an unknown manner and probably will fail badly.
  assert rst_vector'length = check_good'length
    report "check_good not same length as rst_vector" severity error;
  assert rst_vector'length = wait_times'length
    report "wait_times not same length as rst_vector" severity error;
  assert rst_vector'length = move_fast'length
    report "move_fast not same length as rst_vector" severity error;

  reset_sync : process(clk, rst) is
  begin
    if rising_edge(clk) then
      if debounce_counter = to_unsigned(0, db_counter_width) then
        if rst /= sync_rst then
          debounce_counter <= db_counter_init;
          sync_rst <= rst;
        end if;
      else
        debounce_counter <= debounce_counter - 1;
      end if;
    end if;
  end process;

  boot_up : process(clk, sync_rst) is
  begin
    if rising_edge(clk) then
      if sync_rst = '1' then
        timer <= timer_inits(0);
        reset_stage <= (others => '0');
        retry <= '0';
      else
        timer <= timer - 1; -- Decrement unless overriden.
        if retry <= '0' then
          -- Go to next as soon as signal is good
          if move_fast(to_integer(reset_stage)) = '1' then
            -- System is good
            if check_good(to_integer(reset_stage)) = '1' then
              reset_stage <= reset_stage + 1;
              timer <= timer_inits(to_integer(reset_stage) + 1);
            else
              -- Expired before it went good
              if timer = to_unsigned(0, timer_width) then
                timer <= retry_init;
                reset_stage <= reset_stage - 1;
                retry <= '1';
              end if; -- timer
            end if; -- check_good
          -- Change state once timer expires
          else
            if timer = to_unsigned(0, timer_width) then
              -- Next in sequence if check_good is good
              if check_good(to_integer(reset_stage)) = '1' then
                reset_stage <= reset_stage + 1;
                timer <= timer_inits(to_integer(reset_stage) + 1);
              -- Retry if check_good is bad
              else
                reset_stage <= reset_stage - 1;
                timer <= retry_init;
                retry <= '1';
              end if;
            end if;
          end if; -- move_fast
        else -- retry = '1'
          if timer = to_unsigned(0, timer_width) then
            reset_stage <= reset_stage + 1;
            timer <= timer_inits(to_integer(reset_stage) + 1);
            retry <= '0';
          end if;
        end if; -- retry
      end if; -- sync_rst
    end if; -- clk
  end process;

  --! Sets reset vector according to what stage the reset sequencer is at.
  set_resets : process(clk)
  begin
    if rising_edge(clk) then
      if sync_rst = '1' then
        rst_vector <= (rst_vector'range => '1');
      else
        for i in rst_vector'range loop
          if reset_stage >= to_unsigned(i, reset_width) then
            rst_vector(i) <= '1';
          else
            rst_vector(i) <= '0';
          end if;
        end loop;
      end if;
    end if;
  end process;


end rtl;
