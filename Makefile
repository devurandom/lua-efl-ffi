SUBDIRS = gcc-lua gcc-lua-cdecl

CC        = gcc
AWK       = gawk
SED       = sed
CTAGS     = ctags

# Sanity checks
ifeq ($(shell which $(CC)),)
$(error CC=$(CC) not found)
endif
ifeq ($(shell which $(AWK)),)
$(error AWK=$(AWK) not found)
endif
ifeq ($(shell which $(SED)),)
$(error SED=$(SED) not found)
endif
ifeq ($(shell which $(CTAGS)),)
$(error CTAGS=$(CTAGS) not found)
endif

CPPFLAGS  = -I$(FFI_CDECL_DIR)
CFLAGS    = -std=c99 -D_XOPEN_SOURCE=700 -Wall -Wno-deprecated-declarations

GCCLUA    = gcc-lua/gcc/gcclua.so

ifndef FFI_CDECL_DIR
  GCC_CDECL_DIR = gcc-lua-cdecl
  FFI_CDECL_DIR = $(GCC_CDECL_DIR)/ffi-cdecl
  FFI_CDECL_LUA_PATH = $(GCC_CDECL_DIR)/?.lua;$(GCC_CDECL_DIR)/?/init.lua
endif

modules = eina ecore evas elementary
types = enums structs unions types functions defines
version = 1

eina_HEADERS = Eina.h
ecore_HEADERS = Ecore.h Ecore_Getopt.h
evas_HEADERS = Evas.h Evas_GL.h
elementary_HEADERS = Elementary.h

$(foreach mod,$(modules),$(eval $(mod)_CPPFLAGS=$(filter -I%,$(shell pkg-config --cflags $(mod)))))
CPPFLAGS := $(CPPFLAGS) $(foreach mod,$(modules),$($(mod)_CPPFLAGS))

$(foreach mod,$(modules),$(eval $(mod)_CFLAGS=$(filter-out -I%,$(shell pkg-config --cflags $(mod)))))
CFLAGS := $(CFLAGS) $(foreach mod,$(modules),$($(mod)_CFLAGS))

all: $(foreach mod,$(modules),$(mod).lua)

%.lua: %.cdecl.c gcc-lua
	$(CC) -S $(CPPFLAGS) $(CFLAGS) -fplugin=$(GCCLUA) -fplugin-arg-gcclua-script=templates/lua.in.in -fplugin-arg-gcclua-module=$* -fplugin-arg-gcclua-output=$@ -o /dev/null $<

%.collect.c: templates/collect.in
	$(SED) -e "s:<<MODULE>>:$*:g" $< > $@
	$(SED) $(foreach header,$($*_HEADERS), -e "s:<<HEADERS>>:#include <$(header)>\n<<HEADERS>>:") -i $@
	$(SED) -e '/<<HEADERS>>/d' -i $@

%.collect.D: %.collect.c
	$(CPP) -dM $(CPPFLAGS) -o $@ $<

%.collect.E: %.collect.c
	$(CPP) $(CPPFLAGS) -o $@ $<

%.ctags: %.collect.D %.collect.E
	$(CTAGS) -x --language-force=c --c-kinds=degmpstu $^ > $@

%.cdecl.c: templates/cdecl.in %.ctags $(foreach type,$(types),tools/awk-$(type))
	$(SED) -e "s:<<MODULE>>:$*:g" $< > $@
	$(SED) $(foreach header,$($*_HEADERS), -e "s:<<HEADERS>>:#include <$(header)>\n<<HEADERS>>:") -i $@
	$(SED) -e '/<<HEADERS>>/d' -i $@
	$(AWK) -v symbol_include="^(_?$*_|GL)" -v symbol_exclude="^(Eina_Tile_Grid_Info|_Eina_Tile_Grid_Slicer|_Eina_Rbtree|_Eina_Lock|EINA_F32P32_PI)$$" $(foreach type,$(types), -f tools/awk-$(type)) -f tools/awk-dump-collect $*.ctags >> $@

clean: $(SUBDIRS)
	$(RM) -r $(foreach mod,$(modules),$(foreach suffix,lua lua.in cdecl.c collect.c collect.D collect.E ctags,$(mod).$(suffix))) $(foreach mod,$(modules),$(foreach type,$(types),$(foreach suffix,cdecl.c,$(mod).$(type).$(suffix))))

.PHONY: clean $(SUBDIRS)

$(SUBDIRS):
	$(MAKE) -C $@ $(MAKECMDGOALS)
