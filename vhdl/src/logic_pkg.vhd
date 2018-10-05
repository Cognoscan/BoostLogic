--! @file logic_pkg.vhd
--! @brief Package containing all logic entities
--! @author Scott Teal (Scott@Teals.org)
--! @date 2013-09-30
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

package logic_pkg is

  component reset_sequencer is
  generic (
    clk_period : time; --! Period of clk signal
    --! Vector of times to wait/timeout for each reset signal
    wait_times : time_vector;
    retry_time : time; --! Time to keep reset high while retrying
    move_fast : std_logic_vector; --! If '1',  go to next once check_good = '1'
    debounce_time : time --! Time to wait before rst can change again
  );
  port (
    clk : in std_logic; --! Reference clock
    rst : in std_logic; --! Asynchronous reset
    check_good : in std_logic_vector; --! Signals showing subsystems are ready
    rst_vector : out std_logic_vector; --! Reset signals to subsystems
    done : out std_logic --! Indicates sequencer is finished
  );
  end component reset_sequencer;

end package logic_pkg;

package body logic_pkg is

end package body;
