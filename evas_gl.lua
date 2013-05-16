local ffi = require "ffi"
local debug = require "debug"

local __file__ = debug.getinfo(1).source:match("@(.*)$") 
local dir = __file__:match("(.*)/[^/]*$")

local evas_lib = ffi.load("evas")

local evas_gl_E = io.open(dir .. "/pre/evas/Evas_GL.E")
local evas_gl_header = evas_gl_E:read("*a")
evas_gl_E.close()

ffi.cdef[[typedef _Bool Eina_Bool;]]
ffi.cdef[[typedef struct _Evas Evas;]]
ffi.cdef[[typedef struct _Evas_Native_Surface Evas_Native_Surface;]]
ffi.cdef(evas_gl_header)

local evas_gl = {}

evas_gl.lib = evas_lib
evas_gl.def = dofile(dir .. "/pre/evas/Evas_GL.D")

return evas_gl
