AC_DEFUN([xsh_OOT],
[
AC_CHECK_HEADERS(stdarg.h varargs.h termios.h termio.h)

AC_TYPE_SIGNAL

AC_DEFINE([xsh_OOT_MODULE], [], [Out-of-tree module])
])
