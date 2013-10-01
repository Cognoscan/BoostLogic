--! @file reset_sequencer_tb.vhd
--! @brief Test Bench for Reset Sequencer
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
use ieee.math_real.all;

--! Testbench for an entity in boostlogic library
library boostlogic;

--! reset_sequencer Testbench
entity reset_sequencer_tb is
end entity;

--! Simulation of reset_sequencer
architecture sim of reset_sequencer_tb is

  constant clk_period : time := 2 ns;

  -- Test Signals to UUT
  signal clk : std_logic;
  signal rst : std_logic;
  signal rst_vector : std_logic_vector(4 downto 0);
  signal done : std_logic;

begin

  uut : entity boostlogic.reset_sequencer
  generic map (
                clk_period => clk_period,
                wait_times => (10 ns, 20 ns, 30 ns, 40 ns, 50 ns),
                retry_time => 60 ns,
                move_fast => "00000",
                debounce_time => 200 ns
              )
  port map (
             clk => clk,
             rst => rst,
             check_good => "11111",
             rst_vector => rst_vector,
             done => done
           );

  clk_proc : process
  begin
    clk <= '0';
    wait for clk_period / 2;
    clk <= '1';
    wait for clk_period / 2;
  end process;

  rst_proc : process
  begin
    rst <= '1';
    wait for clk_period * 4;
    rst <= '0';
    wait;
  end process;

end sim;

