# Makefile for generating boostlogic VHDL library
#
# Author: Scott Teal (Scott@Teals.org)
# Created: 2013-10-11
#

include Makefile.inc

.PHONY: all basic basic_tb init clean
all: ms_basic

modelsim: ms_basic

modelsim_test: ms_basic_tb



test: ms_basic_tb

ms_basic_tb: ms_basic
	cd src/basic_tb; $(MAKE) $(MFLAGS) modelsim

ms_basic:
	cd src/basic; $(MAKE) $(MFLAGS) modelsim

init:
	vmap -c
	vlib $(LIB_DIR)
	vmap $(LIB_DIR) $(LIB_DIR)
	vlib $(TEST_DIR)
	vmap $(TEST_DIR) $(TEST_DIR)

clean:
	rm modelsim.ini
	rm -r $(LIB_DIR)
	rm -r $(TEST_DIR)

