local ffi = require "ffi"

ffi.cdef[[
union sigval {
  int sival_int;
  void *sival_ptr;
};
struct siginfo {
  int si_signo;
  int si_errno;
  int si_code;
  union {
    int _pad[29];
    struct {
      int si_pid;
      unsigned int si_uid;
    } _kill;
    struct {
      int si_tid;
      int si_overrun;
      union sigval si_sigval;
    } _timer;
    struct {
      int si_pid;
      unsigned int si_uid;
      union sigval si_sigval;
    } _rt;
    struct {
      int si_pid;
      unsigned int si_uid;
      int si_status;
      long int si_utime;
      long int si_stime;
    } _sigchld;
    struct {
      void *si_addr;
    } _sigfault;
    struct {
      long int si_band;
      int si_fd;
    } _sigpoll;
  } _sifields;
};
]]

return ffi.C
