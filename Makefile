DEMISTIFYPATH=DeMiSTify
SUBMODULES=$(DEMISTIFYPATH)/EightThirtyTwo/lib832/lib832.a
PROJECT=Amstrad
PROJECTPATH=./
PROJECTTOROOT=../
BOARD=
ROMSIZE1=8192
ROMSIZE2=8192

# Prevent MiST / MiSTer targets being built if the user supplied the BOARDS variable when invoking make.
TARGETS_NOMIST=$(DEMISTIFYPATH)/site.template $(DEMISTIFYPATH)/site.mk $(SUBMODULES) firmware init compile tns
ifndef BOARDS
	TARGETS = $(TARGETS_NOMIST) mist
else
	TARGETS = $(TARGETS_NOMIST)
endif

all: $(TARGETS)
# Use the file least likely to change within DeMiSTify to detect submodules!
$(DEMISTIFYPATH)/COPYING:
	git submodule update --init --recursive

$(DEMISTIFYPATH)/site.mk: $(DEMISTIFYPATH)/COPYING
	$(info ******************************************************)
	$(info Please copy the example DeMiSTify/site.template file to)
	$(info DeMiSTify/site.mk and edit the paths for the version(s))
	$(info of Quartus you have installed.)
	$(info *******************************************************)
	$(error site.mk not found.)

include $(DEMISTIFYPATH)/site.mk

$(DEMISTIFYPATH)/EightThirtyTwo/Makefile:
	git submodule update --init --recursive

$(SUBMODULES): $(DEMISTIFYPATH)/EightThirtyTwo/Makefile
	make -C $(DEMISTIFYPATH) -f bootstrap.mk

.PHONY: firmware
firmware: $(SUBMODULES)
	make -C firmware -f ../$(DEMISTIFYPATH)/firmware/Makefile DEMISTIFYPATH=../$(DEMISTIFYPATH) ROMSIZE1=$(ROMSIZE1) ROMSIZE2=$(ROMSIZE2)

.PHONY: firmware_clean
firmware_clean: $(SUBMODULES)
	make -C firmware -f ../$(DEMISTIFYPATH)/firmware/Makefile DEMISTIFYPATH=../$(DEMISTIFYPATH) ROMSIZE1=$(ROMSIZE1) ROMSIZE2=$(ROMSIZE2) clean

.PHONY: init
init:
	make -f $(DEMISTIFYPATH)/Makefile DEMISTIFYPATH=$(DEMISTIFYPATH) PROJECTTOROOT=$(PROJECTTOROOT) PROJECTPATH=$(PROJECTPATH) PROJECTS=$(PROJECT) BOARD=$(BOARD) init 

.PHONY: compile
compile: 
	make -f $(DEMISTIFYPATH)/Makefile DEMISTIFYPATH=$(DEMISTIFYPATH) PROJECTTOROOT=$(PROJECTTOROOT) PROJECTPATH=$(PROJECTPATH) PROJECTS=$(PROJECT) BOARD=$(BOARD) compile

.PHONY: clean
clean:
	make -f $(DEMISTIFYPATH)/Makefile DEMISTIFYPATH=$(DEMISTIFYPATH) PROJECTTOROOT=$(PROJECTTOROOT) PROJECTPATH=$(PROJECTPATH) PROJECTS=$(PROJECT) BOARD=$(BOARD) clean

.PHONY: tns
tns:
	@for BOARD in ${BOARDS}; do \
		echo $$BOARD; \
		grep -r Design-wide\ TNS $$BOARD/output_files/*.rpt; \
	done

.PHONY: mist
mist:
	@echo -n "Compiling $(PROJECT) for MiST... "
	@$(QUARTUS_MIST)/quartus_sh >compile.log --flow compile $(PROJECT).qpf \
		&& echo "\033[32mSuccess\033[0m" || grep Error compile.log
	@grep -r Design-wide\ TNS output_files/*.rpt
