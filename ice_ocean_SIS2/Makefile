# Build configuration
BUILD ?= build
MOM_MEMORY ?=
SIS_MEMORY ?=

# Dependencies
FMS_BUILD ?= ../shared/fms/$(BUILD)
ICEBERGS_BUILD ?= ../shared/icebergs/$(BUILD)
ICE_PARAM_BUILD ?= ../shared/ice_param/$(BUILD)
ATMOS_BUILD ?= ../shared/atmos_null/$(BUILD)
LAND_BUILD ?= ../shared/land_null/$(BUILD)

# Autoconf configuration
MOM_CODEBASE ?= ../src/MOM6
MAKEFILE_IN ?= $(MOM_CODEBASE)/ac/Makefile.in
CONFIGURE_AC ?= ../ac/configure.mom6sis2.ac
M4DIR ?= $(MOM_CODEBASE)/ac/m4
MAKEDEP ?= $(MOM_CODEBASE)/ac/makedep

# Run configuration
EXPT ?=
OUTPUT ?= ./$(EXPT)
LAUNCHER ?= mpirun
# The following runs do not appear to work
EXCLUDE ?= \
  OM4_025.JRA \
  SIS2_icebergs \
  SIS2_bergs_cgrid


# Autoconf setup
EXTRA_SRC_DIRS := \
  $(abspath ../src/SIS2/src) \
  $(abspath ../src/SIS2/config_src/external) \
  $(abspath ../src/coupler)

CONFIG_FLAGS := --config-cache
CONFIG_FLAGS += --srcdir=$(abspath $(MOM_CODEBASE))
CONFIG_FLAGS += --with-driver=FMS_cap
ifdef MOM_MEMORY
  CONFIG_FLAGS += MOM_MEMORY=$(abspath $(MOM_MEMORY))
endif
ifdef SIS_MEMORY
  CONFIG_FLAGS += SIS_MEMORY=$(abspath $(SIS_MEMORY))
endif

# NOTE: MOM_FCFLAGS overwrites default; we restore it here
FCFLAGS ?= -g -O2

# Apply coupler preprocessing
CPPFLAGS += \
  -Duse_AM3_physics \
  -D_USE_LEGACY_LAND_

MOM_FCFLAGS := $(FCFLAGS) \
  -I$(abspath $(FMS_BUILD)) \
  -I$(abspath $(ICEBERGS_BUILD)) \
  -I$(abspath $(ICE_PARAM_BUILD)) \
  -I$(abspath $(ATMOS_BUILD)) \
  -I$(abspath $(LAND_BUILD))
MOM_LDFLAGS := $(LDFLAGS) \
  -L$(abspath $(FMS_BUILD)) \
  -L$(abspath $(ICEBERGS_BUILD)) \
  -L$(abspath $(ICE_PARAM_BUILD)) \
  -L$(abspath $(ATMOS_BUILD)) \
  -L$(abspath $(LAND_BUILD))

# TODO: Should be autodetected, but we'll get there...
#   Also, appending -lFMS is a duplication but it needs to follow the others
MOM_LIBS += -licebergs -lice_param -latmos_null -lland_null -lFMS

# Autoconf variables
export CPPFLAGS
export CC
export MPICC
export CFLAGS
export FC
export MPIFC
export FCFLAGS
export LDFLAGS
export LIBS
export PYTHON
export EXTRA_SRC_DIRS


# Makefile setup

# Verify that BUILD is not set to the current directory
# (which would clobber this Makefile)
MAKEPATH = $(realpath $(dir $(abspath $(lastword $(MAKEFILE_LIST)))))
ifeq ($(MAKEPATH), $(realpath $(BUILD)))
  $(error BUILD cannot be set to the current directory)
endif

# Disable builtin rules and variables
MAKEFLAGS += -rR

#---

TARGET := MOM6

all: $(BUILD)/$(TARGET)

$(BUILD)/$(TARGET): $(BUILD)/Makefile
	FCFLAGS="${MOM_FCFLAGS}" \
	LDFLAGS="${MOM_LDFLAGS}" \
	$(MAKE) -C $(BUILD) coupler_main
	@# Rename to MOM6 for MRS compatibility
	@# This can be dropped when MRS is updated (or replaced)
	mv $(BUILD)/coupler_main $(BUILD)/MOM6

$(BUILD)/Makefile: $(FMS_BUILD)/libFMS.a
$(BUILD)/Makefile: $(ATMOS_BUILD)/libatmos_null.a
$(BUILD)/Makefile: $(LAND_BUILD)/libland_null.a
$(BUILD)/Makefile: $(ICE_PARAM_BUILD)/libice_param.a
$(BUILD)/Makefile: $(ICEBERGS_BUILD)/libicebergs.a
$(BUILD)/Makefile: $(BUILD)/Makefile.in $(BUILD)/configure
	cd $(BUILD) && \
	PATH="${PATH}:$(dir $(abspath $(MAKEDEP)))" \
	FCFLAGS="${MOM_FCFLAGS}" \
	LDFLAGS="${MOM_LDFLAGS}" \
	LIBS="${MOM_LIBS}" \
	./configure $(CONFIG_FLAGS)

$(BUILD)/Makefile.in: $(MAKEFILE_IN) | $(BUILD)
	cp $(MAKEFILE_IN) $(BUILD)/Makefile.in

$(BUILD)/configure: $(BUILD)/configure.ac $(BUILD)/m4
	autoreconf $(BUILD)

$(BUILD)/configure.ac: $(CONFIGURE_AC) | $(BUILD)
	cp $(CONFIGURE_AC) $(BUILD)/configure.ac

$(BUILD)/m4: $(M4DIR) | $(BUILD)
	cp -r $(M4DIR) $(BUILD)

$(BUILD):
	mkdir -p $@

#----

# Dependencies

$(FMS_BUILD)/libFMS.a:
	$(MAKE) -C ../shared/fms BUILD=$(BUILD)

$(ATMOS_BUILD)/libatmos_null.a: $(FMS_BUILD)/libFMS.a
	$(MAKE) -C ../shared/atmos_null BUILD=$(BUILD)

$(LAND_BUILD)/libland_null.a: $(FMS_BUILD)/libFMS.a
	$(MAKE) -C ../shared/land_null BUILD=$(BUILD)

$(ICE_PARAM_BUILD)/libice_param.a: $(FMS_BUILD)/libFMS.a
	$(MAKE) -C ../shared/ice_param BUILD=$(BUILD)

$(ICEBERGS_BUILD)/libicebergs.a: $(FMS_BUILD)/libFMS.a
	$(MAKE) -C ../shared/icebergs BUILD=$(BUILD)

#----

# Experiments

EXPTS = $(patsubst ./%/,%,$(dir $(shell find . -name MOM_parameter_doc.all)))
GET_NPROCS = $(abspath ../shared/tools/get_nprocs.sh)

REG_EXPTS = $(filter-out $(EXCLUDE),$(EXPTS))

RUNDIR = $(if $(OUTPUT),$(OUTPUT)/$(1),$(1))

.PHONY: run.all
run.all: $(foreach e,$(REG_EXPTS),run.$(e))

define EXPT_RULE
.PHONY: run.$(1)
run.$(1): $(RUNDIR)/ocean.stats | $(RUNDIR)

$(RUNDIR)/ocean.stats: $(BUILD)/$(TARGET) $(RUNDIR)/input.nml
	mkdir -p $(RUNDIR)/RESTART
	cd $(RUNDIR) && srun -mblock --exclusive -n $$$$($(GET_NPROCS) .) \
	  $(abspath $(BUILD)/$(TARGET))

# TODO: Whitelist the files/dirs to copy?
# TODO: What about symbolic links?
$(RUNDIR)/input.nml: | $(RUNDIR)
	cp -r $(1)/* $(RUNDIR)/

$(RUNDIR):
	mkdir -p $(RUNDIR)

clean.$(1):
	rm -f $(RUNDIR)/CPU_stats
	rm -f $(RUNDIR)/Depth_list.nc
	rm -rf $(RUNDIR)/RESTART
	rm -f $(RUNDIR)/Vertical_coordinate.nc
	rm -f $(RUNDIR)/available_diags.??????
	rm -f $(RUNDIR)/ave_prog__*.nc
	rm -f $(RUNDIR)/cont__*.nc
	rm -f $(RUNDIR)/exitcode
	rm -f $(RUNDIR)/logfile.??????.out
	rm -f $(RUNDIR)/ocean.stats
	rm -f $(RUNDIR)/ocean.stats.nc
	rm -f $(RUNDIR)/ocean_geometry.nc
	rm -f $(RUNDIR)/prog__*.nc
	rm -f $(RUNDIR)/time_stamp.out
endef
$(foreach expt,$(EXPTS),$(eval $(call EXPT_RULE,$(expt))))

#----

.PHONY: clean
clean:
	rm -rf $(BUILD)

.PHONY: clean.runs
clean.runs: $(foreach e,$(EXPTS),clean.$(e))
