# =================================================
# Makefile based Amiga compiler setup.
# (c) Stefan "Bebbo" Franke in 2018
#
# Riding a dead horse...
# =================================================
.SUFFIXES:

# =================================================
# variables
# =================================================
CFLAGS=-Os
CPPFLAGS=-Os
CXXFLAGS=-Os

PREFIX=/opt/amiga
PATH := $(PREFIX)/bin:$(PATH)
SHELL = /bin/bash


# =================================================
# determine exe extension for cygwin
$(eval MYMAKE = $(shell which make) )
$(eval MYMAKEEXE = $(shell which "$(MYMAKE:%=%.exe)") )
EXEEXT=$(MYMAKEEXE:%=.exe)
# =================================================

# =================================================
# help
# =================================================
.PHONY: help
help:
	@echo "make help 			display this help"
	@echo "make all				build and install all"
	@echo "make <target>		builds a target: binutils, gcc"
	@echo "make clean			remove the build folder"
	@echo "make clean-<target>	remove the target's build folder"
	@echo "make clean-prefix	remove all content from the prefix folder"
	@echo "make update			perform git pull for all targets"
	@echo "make update-<target>	perform git pull for the given target"

E=CFLAGS="$(CFLAGS)" CPPFLAGS="$(CPPFLAGS)" CXXFLAGS="$(CXXFLAGS)"

# =================================================
# all
# =================================================
.PHONY: all gcc binutils 
all: gcc binutils
	@echo "built all"

# =================================================
# clean
# =================================================
.PHONY: clean-prefix clean clean-gcc clean-binutils
clean: clean-gcc clean-binutils
	rm -rf build

clean-gcc:
	rm -rf build/gcc	

clean-binutils:
	rm -rf build/binutils	
	
# clean-prefix drops the files from prefix folder
clean-prefix:
	rm -rf $(PREFIX)/*

# =================================================
# update all projects
# =================================================
.PHONY: update update-gcc update-binutils
update: update-gcc update-binutils

update-gcc: projects/gcc/configure
	pushd projects/gcc; git pull; popd

update-binutils: projects/binutils/configure
	pushd projects/binutils; git pull; popd
	
# =================================================
# gcc
# =================================================
CONFIG_GCC=--prefix=$(PREFIX) --target=m68k-amigaos --enable-languages=c,c++,objc --enable-version-specific-runtime-libs --disable-libssp --disable-nls

GCC_CMD = m68k-amigaos-c++ m68k-amigaos-g++ m68k-amigaos-gcc-6.3.1b m68k-amigaos-gcc-nm \
	m68k-amigaos-gcov m68k-amigaos-gcov-tool m68k-amigaos-cpp m68k-amigaos-gcc m68k-amigaos-gcc-ar \
	m68k-amigaos-gcc-ranlib m68k-amigaos-gcov-dump
GCC = $(patsubst %,$(PREFIX)/bin/%$(EXEEXT), $(GCC_CMD))
GCCP = $(patsubst m68k-amigaos%,$(PREFIX)/bin/\%%$(EXEEXT), $(GCC_CMD))

GCC_DIR = . gcc gcc/c gcc/c-family gcc/cp gcc/objc gcc/config/m68k libiberty libcpp libdecnumber 
GCCD = $(patsubst %,projects/gcc/%, $(GCC_DIR))

gcc: $(GCC)
	@echo "built $(GCC)"

$(GCCP): build/gcc/Makefile $(shell find $(GCCD) -maxdepth 1 -type f )
	+pushd build/gcc; make all-gcc install-gcc;	popd
	@true
	
build/gcc/Makefile: projects/gcc/configure
	@mkdir -p build/gcc
	+pushd build/gcc; $(E) $(PWD)/projects/gcc/configure $(CONFIG_GCC); popd

projects/gcc/configure:
	@mkdir -p projects
	pushd projects;	git clone -b gcc-6-branch --depth 1 https://github.com/bebbo/gcc; popd

# =================================================
# binutils
# =================================================
CONFIG_BINUTILS=--prefix=$(PREFIX) --target=m68k-amigaos
BINUTILS_CMD = m68k-amigaos-addr2line m68k-amigaos-ar m68k-amigaos-as m68k-amigaos-c++filt \
	m68k-amigaos-ld m68k-amigaos-nm m68k-amigaos-objcopy m68k-amigaos-objdump m68k-amigaos-ranlib \
	m68k-amigaos-readelf m68k-amigaos-size m68k-amigaos-strings m68k-amigaos-strip
BINUTILS = $(patsubst %,$(PREFIX)/bin/%$(EXEEXT), $(BINUTILS_CMD))
BINUTILSP = $(patsubst m68k-amigaos%,$(PREFIX)/bin/\%%$(EXEEXT), $(BINUTILS_CMD))

BINUTILS_DIR = . bfd gas ld binutils opcodes
BINUTILSD = $(patsubst %,projects/binutils/%, $(BINUTILS_DIR))
	
binutils: $(BINUTILS)
	@echo "built $(BINUTILS)"

$(BINUTILSP): build/binutils/Makefile $(shell find $(BINUTILSD) -maxdepth 1 -type f)
	touch -d19710101 projects/binutils/binutils/arparse.y
	touch -d19710101 projects/binutils/binutils/arlex.l
	touch -d19710101 projects/binutils/ld/ldgram.y 
	+pushd build/binutils; make all install; popd
	
build/binutils/Makefile: projects/binutils/configure 
	@mkdir -p build/binutils
	pushd build/binutils; $(E) $(PWD)/projects/binutils/configure $(CONFIG_BINUTILS); popd

projects/binutils/configure:
	@mkdir -p projects
	pushd projects;	git clone -b master --depth 1 https://github.com/bebbo/amigaos-binutils-2.14 binutils; popd
