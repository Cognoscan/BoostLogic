#
# Makefile for generating tenchbench of basic boostlogic
#
# the basic folder should only contain entities that don't rely on anything else 
# in the library except for the utility packages. Their test benches should 
# be included here.
#

include ../../Makefile.inc

VHDL = $(shell find -type f -name '*.vhd')

COMPILED = $(patsubst %.vhd, ../../$(TEST_DIR)/%/_primary.dat, $(VHDL))

.PHONY: all
all: modelsim
	
modelsim: $(COMPILED)

../../$(TEST_DIR)/%/_primary.dat: %.vhd
	cd ../..;	$(VCOM) -work $(TEST_DIR) ./src/basic_tb/$<


