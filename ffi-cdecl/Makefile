CC        = gcc
CPPFLAGS  = -I$(FFI_CDECL_DIR)
CFLAGS    = -std=c99 -Wall
GCCLUA    = $(CURDIR)/../gcc-lua/gcc/gcclua.so
FFI_CDECL = $(FFI_CDECL_DIR)/ffi-cdecl.lua

ifndef FFI_CDECL_DIR
  GCC_CDECL_DIR = $(CURDIR)/../gcc-lua-cdecl
  FFI_CDECL_DIR = $(GCC_CDECL_DIR)/ffi-cdecl
  ifdef LUA_PATH
    LUA_PATH := $(GCC_CDECL_DIR)/?.lua;$(GCC_CDECL_DIR)/?/init.lua;$(LUA_PATH)
  else
    LUA_PATH := $(GCC_CDECL_DIR)/?.lua;$(GCC_CDECL_DIR)/?/init.lua;;
  endif
  export LUA_PATH
endif

types = enums structs types functions defines
modules = ecore evas elementary
skip_headers = Ecore_X% Evas_Engine_% elm_route% elm_widget% elm_interface%
version = 1

getcflags = $(shell pkg-config --cflags $(1))
getinclude = $(patsubst -I%,%,$(filter %$(1)-$(version),$(filter -I%,$($(1)_CFLAGS))))
getheaders = $(foreach header,$($(1)_HEADERS),$($(1)_INCLUDE)/$(header))

$(foreach mod,$(modules),$(eval $(mod)_CFLAGS=$(call getcflags,$(mod))))
$(foreach mod,$(modules),$(eval $(mod)_INCLUDE=$(call getinclude,$(mod))))
$(foreach mod,$(modules),$(eval $(mod)_HEADERS=$(filter-out $(skip_headers),$(notdir $(wildcard $($(mod)_INCLUDE)/*.h)))))

CFLAGS := $(CFLAGS) $(foreach mod,$(modules),$($(mod)_CFLAGS))

all: $(foreach mod,$(modules),$(mod).lua)

%.lua: %.c %.lua.in $(foreach type,$(types),%.$(type).c)
	$(CC) -S $< -fplugin=$(GCCLUA) -fplugin-arg-gcclua-script=$(FFI_CDECL) -fplugin-arg-gcclua-input=$*.lua.in -fplugin-arg-gcclua-output=$@ $(CPPFLAGS) $(CFLAGS)

clean:
	$(RM) -r $(foreach mod,$(modules),$(foreach suffix,lua lua.in c ctags,$(mod).$(suffix))) $(foreach mod,$(modules),$(foreach type,$(types),$(foreach suffix,c pre.c,$(mod).$(type).$(suffix))))

.PHONY: clean

define makerule-ctags
$(1).ctags: $(2)
	ctags -x $(2) > $$@
endef

define makerule-type-c
$(1).$(2).c: $(1).ctags
	awk -f ../tools/awk-$(2) $$< | uniq > $$@

endef

define makerule-lua
$(1).lua.in: lua.in.in
	sed "s/<<MODULE>>/$(1)/g" $$< > $$@
endef

define makerule-c
$(1).c: c.in $(foreach type,$(types),$(1).$(type).c)
	sed "s/<<MODULE>>/$(1)/g" $$< > $$@
	$(foreach header,$($(1)_HEADERS),sed "s/<<HEADERS>>/#include <$(header)>\n<<HEADERS>>/" -i $$@ &&) test $$$$? -eq 0
	sed '/<<HEADERS>>/d' -i $$@
	$(foreach type,$(types),sed "/<<SOURCES>>/r $(1).$(type).c" -i $$@ &&) test $$$$? -eq 0
	sed '/<<SOURCES>>/d' -i $$@
endef

$(foreach mod,$(modules),$(foreach type,$(types),$(eval $(call makerule-type-c,$(mod),$(type)))))
$(foreach mod,$(modules),$(eval $(call makerule-lua,$(mod))))
$(foreach mod,$(modules),$(eval $(call makerule-ctags,$(mod),$(call getheaders,$(mod)))))

# Many elc_ and elm_ headers lack header guards, thus we can only include the main header:
elementary_HEADERS = Elementary.h

$(foreach mod,$(modules),$(eval $(call makerule-c,$(mod))))
