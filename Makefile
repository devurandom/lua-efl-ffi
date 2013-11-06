SUBDIRS = gcc-lua gcc-lua-cdecl ffi-cdecl

.PHONY: clean subdirs $(SUBDIRS)

clean: subdirs
subdirs: $(SUBDIRS)

$(SUBDIRS):
	$(MAKE) -C $@ $(MAKECMDGOALS)

gcc-lua-cdecl: gcc-lua
ffi-cdecl: gcc-lua-cdecl
