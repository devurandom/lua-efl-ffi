local ffi = require "ffi"

ffi.cdef[[
union sigval {
  int sival_int;
  void *sival_ptr;
};
]]

return ffi.C
