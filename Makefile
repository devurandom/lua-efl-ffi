SUBDIRS = gcc-lua gcc-lua-cdecl

CC        = gcc
AWK       = gawk
SED       = sed
CTAGS     = ctags
UNIQ      = uniq

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
ifeq ($(shell which $(UNIQ)),)
$(error UNIQ=$(UNIQ) not found)
endif

CPPFLAGS  = -I$(FFI_CDECL_DIR)
CFLAGS    = -std=c99 -D_XOPEN_SOURCE=700 -Wall -Wno-deprecated-declarations

GCCLUA    = gcc-lua/gcc/gcclua.so
FFI_CDECL = $(FFI_CDECL_DIR)/ffi-cdecl.lua

ifndef FFI_CDECL_DIR
  GCC_CDECL_DIR = gcc-lua-cdecl
  FFI_CDECL_DIR = $(GCC_CDECL_DIR)/ffi-cdecl
  FFI_CDECL_LUA_PATH = $(GCC_CDECL_DIR)/?.lua;$(GCC_CDECL_DIR)/?/init.lua
  ifdef LUA_PATH
    LUA_PATH := $(FFI_CDECL_LUA_PATH);$(LUA_PATH)
  else
    LUA_PATH := $(FFI_CDECL_LUA_PATH);;
  endif
  ifdef LUA_PATH_5_2
    LUA_PATH_5_2 := $(FFI_CDECL_LUA_PATH);$(LUA_PATH_5_2)
  else
    LUA_PATH_5_2 := $(FFI_CDECL_LUA_PATH);;
  endif
  export LUA_PATH LUA_PATH_5_2
endif

types = enums structs types functions defines
modules = ecore evas elementary
skip_headers = Ecore_X% Evas_Engine_% Ecore_Wayland.h elm_route% elm_widget% elm_interface%
version = 1

getcflags = $(shell pkg-config --cflags $(1))
getinclude = $(patsubst -I%,%,$(filter %$(1)-$(version),$(filter -I%,$($(1)_CFLAGS))))
getheaders = $(foreach header,$($(1)_HEADERS),$($(1)_INCLUDE)/$(header))

$(foreach mod,$(modules),$(eval $(mod)_CFLAGS=$(call getcflags,$(mod))))
$(foreach mod,$(modules),$(eval $(mod)_INCLUDE=$(call getinclude,$(mod))))
$(foreach mod,$(modules),$(eval $(mod)_HEADERS=$(filter-out $(skip_headers),$(notdir $(wildcard $($(mod)_INCLUDE)/*.h)))))

CFLAGS := $(CFLAGS) $(foreach mod,$(modules),$($(mod)_CFLAGS))

all: $(foreach mod,$(modules),$(mod).lua)

%.lua: %.c %.lua.in $(foreach type,$(types),%.$(type).c) gcc-lua
	$(CC) -S $< -fplugin=$(GCCLUA) -fplugin-arg-gcclua-script=$(FFI_CDECL) -fplugin-arg-gcclua-input=$*.lua.in -fplugin-arg-gcclua-output=$@ $(CPPFLAGS) $(CFLAGS)

clean: $(SUBDIRS)
	$(RM) -r $(foreach mod,$(modules),$(foreach suffix,lua lua.in c ctags,$(mod).$(suffix))) $(foreach mod,$(modules),$(foreach type,$(types),$(foreach suffix,c pre.c,$(mod).$(type).$(suffix))))

.PHONY: clean $(SUBDIRS)

$(SUBDIRS):
	$(MAKE) -C $@ $(MAKECMDGOALS)

define makerule-ctags
$(1).ctags: $(2)
	$(CTAGS) -x --c-kinds=degmpstu $(2) > $$@
endef

define makerule-type-c
$(1).$(2).c: $(1).ctags tools/awk-$(2)
	$(AWK) -v symbol_pattern="^(_$(1)|$(1)|GL)" -f tools/awk-$(2) $$< > $$@.tmp
	$(UNIQ) < $$@.tmp > $$@
	$(RM) -f $$@.tmp
endef

define makerule-lua
$(1).lua.in: templates/lua.in.in
	$(SED) "s/<<MODULE>>/$(1)/g" $$< > $$@
endef

define makerule-c
$(1).c: templates/c.in $(foreach type,$(types),$(1).$(type).c)
	$(SED) "s/<<MODULE>>/$(1)/g" $$< > $$@
	$(foreach header,$($(1)_HEADERS),$(SED) "s/<<HEADERS>>/#include <$(header)>\n<<HEADERS>>/" -i $$@ &&) test $$$$? -eq 0
	$(SED) '/<<HEADERS>>/d' -i $$@
	$(foreach type,$(types),$(SED) "/<<SOURCES>>/r $(1).$(type).c" -i $$@ &&) test $$$$? -eq 0
	$(SED) '/<<SOURCES>>/d' -i $$@
endef

$(foreach mod,$(modules),$(foreach type,$(types),$(eval $(call makerule-type-c,$(mod),$(type)))))
$(foreach mod,$(modules),$(eval $(call makerule-lua,$(mod))))
$(foreach mod,$(modules),$(eval $(call makerule-ctags,$(mod),$(call getheaders,$(mod)))))

# Many elc_ and elm_ headers lack header guards, thus we can only include the main header:
elementary_HEADERS = Elementary.h

# Several headers do not contain all necessary includes, so we put them manually in front
ecore_HEADERS := Ecore.h Ecore_Input.h ${ecore_HEADERS}
evas_HEADERS := Evas.h ${evas_HEADERS}

$(foreach mod,$(modules),$(eval $(call makerule-c,$(mod))))
