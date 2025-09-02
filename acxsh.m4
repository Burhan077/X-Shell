dnl
dnl  Autconf tests for xsh.
dnl
dnl  Copyright (c) 1995-1997 Richard Coleman
dnl  All rights reserved.
dnl
dnl  Permission is hereby granted, without written agreement and without
dnl  license or royalty fees, to use, copy, modify, and distribute this
dnl  software and to distribute modified versions of this software for any
dnl  purpose, provided that the above copyright notice and the following
dnl  two paragraphs appear in all copies of this software.
dnl
dnl  In no event shall Richard Coleman or the xsh Development Group be liable
dnl  to any party for direct, indirect, special, incidental, or consequential
dnl  damages arising out of the use of this software and its documentation,
dnl  even if Richard Coleman and the xsh Development Group have been advised of
dnl  the possibility of such damage.
dnl
dnl  Richard Coleman and the xsh Development Group specifically disclaim any
dnl  warranties, including, but not limited to, the implied warranties of
dnl  merchantability and fitness for a particular purpose.  The software
dnl  provided hereunder is on an "as is" basis, and Richard Coleman and the
dnl  xsh Development Group have no obligation to provide maintenance,
dnl  support, updates, enhancements, or modifications.
dnl

dnl
dnl xsh_64_BIT_TYPE
dnl   Check whether the first argument works as a 64-bit type.
dnl   If there is a non-zero third argument, we just assume it works
dnl   when we're cross compiling.  This is to allow a type to be
dnl   specified directly as --enable-lfs="long long".
dnl   Sets the variable given in the second argument to the first argument
dnl   if the test worked, `no' otherwise.  Be careful testing this, as it
dnl   may produce two words `long long' on an unquoted substitution.
dnl   Also check that the compiler does not mind it being cast to int.
dnl   This macro does not produce messages as it may be run several times
dnl   before finding the right type.
dnl

AC_DEFUN(xsh_64_BIT_TYPE,
[AC_RUN_IFELSE([AC_LANG_SOURCE([[
#ifdef HAVE_SYS_TYPES_H
#include <sys/types.h>
#endif

int
main()
{
  $1 foo = 0; 
  int bar = (int) foo;
  return sizeof($1) != 8;
}
]])],[$2="$1"],[$2=no],
  [if test x$3 != x ; then
    $2="$1"
  else
    $2=no
  fi])
])


dnl
dnl xsh_SHARED_FUNCTION
dnl
dnl This is just a frontend to xsh_SHARED_SYMBOL
dnl
dnl Usage: xsh_SHARED_FUNCTION(name[,rettype[,paramtype]])
dnl

AC_DEFUN(xsh_SHARED_FUNCTION,
[xsh_SHARED_SYMBOL($1, ifelse([$2], ,[int ],[$2]) $1 [(]ifelse([$3], ,[ ],[$3])[)], $1)])

dnl
dnl xsh_SHARED_VARIABLE
dnl
dnl This is just a frontend to xsh_SHARED_SYMBOL
dnl
dnl Usage: xsh_SHARED_VARIABLE(name[,type])
dnl

AC_DEFUN(xsh_SHARED_VARIABLE,
[xsh_SHARED_SYMBOL($1, ifelse([$2], ,[int ],[$2]) $1, [&$1])])

dnl
dnl xsh_SHARED_SYMBOL
dnl   Check whether symbol is available in static or shared library
dnl
dnl   On some systems, static modifiable library symbols (such as environ)
dnl   may appear only in statically linked libraries.  If this is the case,
dnl   then two shared libraries that reference the same symbol, each linked
dnl   with the static library, could be given distinct copies of the symbol.
dnl
dnl Usage: xsh_SHARED_SYMBOL(name,declaration,address)
dnl Sets xsh_cv_shared_$1 cache variable to yes/no
dnl

AC_DEFUN(xsh_SHARED_SYMBOL,
[AC_CACHE_CHECK([if $1 is available in shared libraries],
xsh_cv_shared_$1,
[if test "$xsh_cv_func_dlsym_needs_underscore" = yes; then
    us=_
else
    us=
fi
echo '
void *xsh_getaddr1()
{
#ifdef __CYGWIN__
	__attribute__((__dllimport__))	
#endif
	extern $2;
	return $3;
};
' > conftest1.c
sed 's/xsh_getaddr1/xsh_getaddr2/' < conftest1.c > conftest2.c
if AC_TRY_COMMAND($CC -c $CFLAGS $CPPFLAGS $DLCFLAGS conftest1.c 1>&AS_MESSAGE_LOG_FD) &&
AC_TRY_COMMAND($DLLD -o conftest1.$DL_EXT $LDFLAGS $DLLDFLAGS conftest1.o $LIBS 1>&AS_MESSAGE_LOG_FD) &&
AC_TRY_COMMAND($CC -c $CFLAGS $CPPFLAGS $DLCFLAGS conftest2.c 1>&AS_MESSAGE_LOG_FD) &&
AC_TRY_COMMAND($DLLD -o conftest2.$DL_EXT $LDFLAGS $DLLDFLAGS conftest2.o $LIBS 1>&AS_MESSAGE_LOG_FD); then
    AC_RUN_IFELSE([AC_LANG_SOURCE([[
#ifdef HPUX10DYNAMIC
#include <dl.h>
#define RTLD_LAZY BIND_DEFERRED
#define RTLD_GLOBAL DYNAMIC_PATH

char *xsh_gl_sym_addr ;

#define dlopen(file,mode) (void *)shl_load((file), (mode), (long) 0)
#define dlclose(handle) shl_unload((shl_t)(handle))
#define dlsym(handle,name) (xsh_gl_sym_addr=0,shl_findsym((shl_t *)&(handle),name,TYPE_UNDEFINED,&xsh_gl_sym_addr), (void *)xsh_gl_sym_addr)
#define dlerror() 0
#else
#ifdef HAVE_DLFCN_H
#include <dlfcn.h>
#else
#include <sys/types.h>
#include <nlist.h>
#include <link.h>
#endif
#endif
#ifndef RTLD_LAZY
#define RTLD_LAZY 1
#endif
#ifndef RTLD_GLOBAL
#define RTLD_GLOBAL 0
#endif

int
main()
{
    void *handle1, *handle2;
    void *(*xsh_getaddr1)(), *(*xsh_getaddr2)();
    void *sym1, *sym2;
    handle1 = dlopen("./conftest1.$DL_EXT", RTLD_LAZY | RTLD_GLOBAL);
    if(!handle1) return(1);
    handle2 = dlopen("./conftest2.$DL_EXT", RTLD_LAZY | RTLD_GLOBAL);
    if(!handle2) return(1);
    xsh_getaddr1 = (void *(*)()) dlsym(handle1, "${us}xsh_getaddr1");
    xsh_getaddr2 = (void *(*)()) dlsym(handle2, "${us}xsh_getaddr2");
    sym1 = xsh_getaddr1();
    sym2 = xsh_getaddr2();
    if(!sym1 || !sym2) return(1);
    if(sym1 != sym2) return(1);
    dlclose(handle1);
    handle1 = dlopen("./conftest1.$DL_EXT", RTLD_LAZY | RTLD_GLOBAL);
    if(!handle1) return(1);
    xsh_getaddr1 = (void *(*)()) dlsym(handle1, "${us}xsh_getaddr1");
    sym1 = xsh_getaddr1();
    if(!sym1) return(1);
    if(sym1 != sym2) return(1);
    return(0);
}
]])],[xsh_cv_shared_$1=yes],
[xsh_cv_shared_$1=no],
[xsh_cv_shared_$1=no]
)
else
    xsh_cv_shared_$1=no
fi
])
])

dnl
dnl xsh_SYS_DYNAMIC_CLASH
dnl   Check whether symbol name clashes in shared libraries are acceptable.
dnl

AC_DEFUN(xsh_SYS_DYNAMIC_CLASH,
[AC_CACHE_CHECK([if name clashes in shared objects are OK],
xsh_cv_sys_dynamic_clash_ok,
[if test "$xsh_cv_func_dlsym_needs_underscore" = yes; then
    us=_
else
    us=
fi
echo 'int fred () { return 42; }' > conftest1.c
echo 'int fred () { return 69; }' > conftest2.c
if AC_TRY_COMMAND($CC -c $CFLAGS $CPPFLAGS $DLCFLAGS conftest1.c 1>&AS_MESSAGE_LOG_FD) &&
AC_TRY_COMMAND($DLLD -o conftest1.$DL_EXT $LDFLAGS $DLLDFLAGS conftest1.o $LIBS 1>&AS_MESSAGE_LOG_FD) &&
AC_TRY_COMMAND($CC -c $CFLAGS $CPPFLAGS $DLCFLAGS conftest2.c 1>&AS_MESSAGE_LOG_FD) &&
AC_TRY_COMMAND($DLLD -o conftest2.$DL_EXT $LDFLAGS $DLLDFLAGS conftest2.o $LIBS 1>&AS_MESSAGE_LOG_FD); then
    AC_RUN_IFELSE([AC_LANG_SOURCE([[
#ifdef HPUX10DYNAMIC
#include <dl.h>
#define RTLD_LAZY BIND_DEFERRED
#define RTLD_GLOBAL DYNAMIC_PATH

char *xsh_gl_sym_addr ;

#define dlopen(file,mode) (void *)shl_load((file), (mode), (long) 0)
#define dlclose(handle) shl_unload((shl_t)(handle))
#define dlsym(handle,name) (xsh_gl_sym_addr=0,shl_findsym((shl_t *)&(handle),name,TYPE_UNDEFINED,&xsh_gl_sym_addr), (void *)xsh_gl_sym_addr)
#define dlerror() 0
#else
#ifdef HAVE_DLFCN_H
#include <dlfcn.h>
#else
#include <sys/types.h>
#include <nlist.h>
#include <link.h>
#endif
#endif
#ifndef RTLD_LAZY
#define RTLD_LAZY 1
#endif
#ifndef RTLD_GLOBAL
#define RTLD_GLOBAL 0
#endif

int
main()
{
    void *handle1, *handle2;
    int (*fred1)(), (*fred2)();
    handle1 = dlopen("./conftest1.$DL_EXT", RTLD_LAZY | RTLD_GLOBAL);
    if(!handle1) return(1);
    handle2 = dlopen("./conftest2.$DL_EXT", RTLD_LAZY | RTLD_GLOBAL);
    if(!handle2) return(1);
    fred1 = (int (*)()) dlsym(handle1, "${us}fred");
    fred2 = (int (*)()) dlsym(handle2, "${us}fred");
    if(!fred1 || !fred2) return(1);
    return((*fred1)() != 42 || (*fred2)() != 69);
}
]])],[xsh_cv_sys_dynamic_clash_ok=yes],
[xsh_cv_sys_dynamic_clash_ok=no],
[xsh_cv_sys_dynamic_clash_ok=no]
)
else
    xsh_cv_sys_dynamic_clash_ok=no
fi
])
if test "$xsh_cv_sys_dynamic_clash_ok" = yes; then
    AC_DEFINE(DYNAMIC_NAME_CLASH_OK)
fi
])

dnl
dnl xsh_SYS_DYNAMIC_GLOBAL
dnl   Check whether symbols in one dynamically loaded library are
dnl   available to another dynamically loaded library.
dnl

AC_DEFUN(xsh_SYS_DYNAMIC_GLOBAL,
[AC_CACHE_CHECK([for working RTLD_GLOBAL],
xsh_cv_sys_dynamic_rtld_global,
[if test "$xsh_cv_func_dlsym_needs_underscore" = yes; then
    us=_
else
    us=
fi
echo 'int fred () { return 42; }' > conftest1.c
echo 'extern int fred(); int barney () { return fred() + 27; }' > conftest2.c
if AC_TRY_COMMAND($CC -c $CFLAGS $CPPFLAGS $DLCFLAGS conftest1.c 1>&AS_MESSAGE_LOG_FD) &&
AC_TRY_COMMAND($DLLD -o conftest1.$DL_EXT $LDFLAGS $DLLDFLAGS conftest1.o $LIBS 1>&AS_MESSAGE_LOG_FD) &&
AC_TRY_COMMAND($CC -c $CFLAGS $CPPFLAGS $DLCFLAGS conftest2.c 1>&AS_MESSAGE_LOG_FD) &&
AC_TRY_COMMAND($DLLD -o conftest2.$DL_EXT $LDFLAGS $DLLDFLAGS conftest2.o $LIBS 1>&AS_MESSAGE_LOG_FD); then
    AC_RUN_IFELSE([AC_LANG_SOURCE([[
#ifdef HPUX10DYNAMIC
#include <dl.h>
#define RTLD_LAZY BIND_DEFERRED
#define RTLD_GLOBAL DYNAMIC_PATH

char *xsh_gl_sym_addr ;

#define dlopen(file,mode) (void *)shl_load((file), (mode), (long) 0)
#define dlclose(handle) shl_unload((shl_t)(handle))
#define dlsym(handle,name) (xsh_gl_sym_addr=0,shl_findsym((shl_t *)&(handle),name,TYPE_UNDEFINED,&xsh_gl_sym_addr), (void *)xsh_gl_sym_addr)
#define dlerror() 0
#else
#ifdef HAVE_DLFCN_H
#include <dlfcn.h>
#else
#include <sys/types.h>
#include <nlist.h>
#include <link.h>
#endif
#endif
#ifndef RTLD_LAZY
#define RTLD_LAZY 1
#endif
#ifndef RTLD_GLOBAL
#define RTLD_GLOBAL 0
#endif

int
main()
{
    void *handle;
    int (*barneysym)();
    handle = dlopen("./conftest1.$DL_EXT", RTLD_LAZY | RTLD_GLOBAL);
    if(!handle) return(1);
    handle = dlopen("./conftest2.$DL_EXT", RTLD_LAZY | RTLD_GLOBAL);
    if(!handle) return(1);
    barneysym = (int (*)()) dlsym(handle, "${us}barney");
    if(!barneysym) return(1);
    return((*barneysym)() != 69);
}
]])],[xsh_cv_sys_dynamic_rtld_global=yes],
[xsh_cv_sys_dynamic_rtld_global=no],
[xsh_cv_sys_dynamic_rtld_global=no]
)
else
    xsh_cv_sys_dynamic_rtld_global=no
fi
])
])

dnl
dnl xsh_SYS_DYNAMIC_EXECSYMS
dnl   Check whether symbols in the executable are available to dynamically
dnl   loaded libraries.
dnl

AC_DEFUN(xsh_SYS_DYNAMIC_EXECSYMS,
[AC_CACHE_CHECK([whether symbols in the executable are available],
xsh_cv_sys_dynamic_execsyms,
[if test "$xsh_cv_func_dlsym_needs_underscore" = yes; then
    us=_
else
    us=
fi
echo 'extern int fred(); int barney () { return fred() + 27; }' > conftest1.c
if AC_TRY_COMMAND($CC -c $CFLAGS $CPPFLAGS $DLCFLAGS conftest1.c 1>&AS_MESSAGE_LOG_FD) &&
AC_TRY_COMMAND($DLLD -o conftest1.$DL_EXT $LDFLAGS $DLLDFLAGS conftest1.o $LIBS 1>&AS_MESSAGE_LOG_FD); then
    save_ldflags=$LDFLAGS
    LDFLAGS="$LDFLAGS $EXTRA_LDFLAGS"
    AC_RUN_IFELSE([AC_LANG_SOURCE([[
#ifdef HPUX10DYNAMIC
#include <dl.h>
#define RTLD_LAZY BIND_DEFERRED
#define RTLD_GLOBAL DYNAMIC_PATH

char *xsh_gl_sym_addr ;

#define dlopen(file,mode) (void *)shl_load((file), (mode), (long) 0)
#define dlclose(handle) shl_unload((shl_t)(handle))
#define dlsym(handle,name) (xsh_gl_sym_addr=0,shl_findsym((shl_t *)&(handle),name,TYPE_UNDEFINED,&xsh_gl_sym_addr), (void *)xsh_gl_sym_addr)
#define dlerror() 0
#else
#ifdef HAVE_DLFCN_H
#include <dlfcn.h>
#else
#include <sys/types.h>
#include <nlist.h>
#include <link.h>
#endif
#endif
#ifndef RTLD_LAZY
#define RTLD_LAZY 1
#endif
#ifndef RTLD_GLOBAL
#define RTLD_GLOBAL 0
#endif

int
main()
{
    void *handle;
    int (*barneysym)();
    handle = dlopen("./conftest1.$DL_EXT", RTLD_LAZY | RTLD_GLOBAL);
    if(!handle) return(1);
    barneysym = (int (*)()) dlsym(handle, "${us}barney");
    if(!barneysym) return(1);
    return((*barneysym)() != 69);
}

int fred () { return 42; }
]])],[xsh_cv_sys_dynamic_execsyms=yes],
[xsh_cv_sys_dynamic_execsyms=no],
[xsh_cv_sys_dynamic_execsyms=no]
)
    LDFLAGS=$save_ldflags
else
    xsh_cv_sys_dynamic_execsyms=no
fi
])
])

dnl
dnl xsh_SYS_DYNAMIC_STRIP_EXE
dnl   Check whether it is safe to strip executables.
dnl

AC_DEFUN(xsh_SYS_DYNAMIC_STRIP_EXE,
[AC_REQUIRE([xsh_SYS_DYNAMIC_EXECSYMS])
AC_CACHE_CHECK([whether executables can be stripped],
xsh_cv_sys_dynamic_strip_exe,
[if test "$xsh_cv_sys_dynamic_execsyms" != yes; then
    xsh_cv_sys_dynamic_strip_exe=yes
elif
    if test "$xsh_cv_func_dlsym_needs_underscore" = yes; then
	us=_
    else
	us=
    fi
    echo 'extern int fred(); int barney() { return fred() + 27; }' > conftest1.c
    AC_TRY_COMMAND($CC -c $CFLAGS $CPPFLAGS $DLCFLAGS conftest1.c 1>&AS_MESSAGE_LOG_FD) &&
    AC_TRY_COMMAND($DLLD -o conftest1.$DL_EXT $LDFLAGS $DLLDFLAGS conftest1.o $LIBS 1>&AS_MESSAGE_LOG_FD); then
    save_ldflags=$LDFLAGS
    LDFLAGS="$LDFLAGS $EXTRA_LDFLAGS -s"
    AC_RUN_IFELSE([AC_LANG_SOURCE([[
#ifdef HPUX10DYNAMIC
#include <dl.h>
#define RTLD_LAZY BIND_DEFERRED
#define RTLD_GLOBAL DYNAMIC_PATH

char *xsh_gl_sym_addr ;

#define dlopen(file,mode) (void *)shl_load((file), (mode), (long) 0)
#define dlclose(handle) shl_unload((shl_t)(handle))
#define dlsym(handle,name) (xsh_gl_sym_addr=0,shl_findsym((shl_t *)&(handle),name,TYPE_UNDEFINED,&xsh_gl_sym_addr), (void *)xsh_gl_sym_addr)
#define dlerror() 0
#else
#ifdef HAVE_DLFCN_H
#include <dlfcn.h>
#else
#include <sys/types.h>
#include <nlist.h>
#include <link.h>
#endif
#endif
#ifndef RTLD_LAZY
#define RTLD_LAZY 1
#endif
#ifndef RTLD_GLOBAL
#define RTLD_GLOBAL 0
#endif

int
main()
{
    void *handle;
    int (*barneysym)();
    handle = dlopen("./conftest1.$DL_EXT", RTLD_LAZY | RTLD_GLOBAL);
    if(!handle) return(1);
    barneysym = (int (*)()) dlsym(handle, "${us}barney");
    if(!barneysym) return(1);
    return((*barneysym)() != 69);
}

int fred () { return 42; }
]])],[xsh_cv_sys_dynamic_strip_exe=yes],
[xsh_cv_sys_dynamic_strip_exe=no],
[xsh_cv_sys_dynamic_strip_exe=no]
)
    LDFLAGS=$save_ldflags
else
    xsh_cv_sys_dynamic_strip_exe=no
fi
])
])

dnl
dnl xsh_SYS_DYNAMIC_STRIP_EXE
dnl   Check whether it is safe to strip dynamically loaded libraries.
dnl

AC_DEFUN(xsh_SYS_DYNAMIC_STRIP_LIB,
[AC_CACHE_CHECK([whether libraries can be stripped],
xsh_cv_sys_dynamic_strip_lib,
[if test "$xsh_cv_func_dlsym_needs_underscore" = yes; then
    us=_
else
    us=
fi
echo 'int fred () { return 42; }' > conftest1.c
if AC_TRY_COMMAND($CC -c $CFLAGS $CPPFLAGS $DLCFLAGS conftest1.c 1>&AS_MESSAGE_LOG_FD) &&
AC_TRY_COMMAND($DLLD -o conftest1.$DL_EXT $LDFLAGS $DLLDFLAGS -s conftest1.o $LIBS 1>&AS_MESSAGE_LOG_FD); then
    AC_RUN_IFELSE([AC_LANG_SOURCE([[
#ifdef HPUX10DYNAMIC
#include <dl.h>
#define RTLD_LAZY BIND_DEFERRED
#define RTLD_GLOBAL DYNAMIC_PATH

char *xsh_gl_sym_addr ;

#define dlopen(file,mode) (void *)shl_load((file), (mode), (long) 0)
#define dlclose(handle) shl_unload((shl_t)(handle))
#define dlsym(handle,name) (xsh_gl_sym_addr=0,shl_findsym((shl_t *)&(handle),name,TYPE_UNDEFINED,&xsh_gl_sym_addr), (void *)xsh_gl_sym_addr)
#define dlerror() 0
#else
#ifdef HAVE_DLFCN_H
#include <dlfcn.h>
#else
#include <sys/types.h>
#include <nlist.h>
#include <link.h>
#endif
#endif
#ifndef RTLD_LAZY
#define RTLD_LAZY 1
#endif
#ifndef RTLD_GLOBAL
#define RTLD_GLOBAL 0
#endif

int
main()
{
    void *handle;
    int (*fredsym)();
    handle = dlopen("./conftest1.$DL_EXT", RTLD_LAZY | RTLD_GLOBAL);
    if(!handle) return(1);
    fredsym = (int (*)()) dlsym(handle, "${us}fred");
    if(!fredsym) return(1);
    return((*fredsym)() != 42);
}
]])],[xsh_cv_sys_dynamic_strip_lib=yes],
[xsh_cv_sys_dynamic_strip_lib=no],
[xsh_cv_sys_dynamic_strip_lib=no]
)
else
    xsh_cv_sys_dynamic_strip_lib=no
fi
])
])

dnl
dnl xsh_PATH_UTMP(filename)
dnl   Search for a specified utmp-type file.
dnl

AC_DEFUN(xsh_PATH_UTMP,
[AC_CACHE_CHECK([for $1 file], [xsh_cv_path_$1],
[for dir in /etc /usr/etc /var/adm /usr/adm /var/run /var/log ./conftest; do
  m4_foreach([file],[$@],[xsh_cv_path_$1=${dir}/file
  test -f $xsh_cv_path_$1 && break
  ])xsh_cv_path_$1=no
done
])
AH_TEMPLATE([PATH_]translit($1, [a-z], [A-Z])[_FILE],
[Define to be location of ]$1[ file.])
if test $xsh_cv_path_$1 != no; then
  AC_DEFINE_UNQUOTED([PATH_]translit($1, [a-z], [A-Z])[_FILE],
  "$xsh_cv_path_$1")
fi
])

dnl
dnl xsh_TYPE_EXISTS(#includes, type name)
dnl   Check whether a specified type exists.
dnl

AC_DEFUN(xsh_TYPE_EXISTS,
[AC_CACHE_CHECK([for $2], [xsh_cv_type_exists_[]translit($2, [ ], [_])],
[AC_COMPILE_IFELSE([AC_LANG_PROGRAM([[$1]], [[$2 testvar;]])],
[xsh_cv_type_exists_[]translit($2, [ ], [_])=yes],
[xsh_cv_type_exists_[]translit($2, [ ], [_])=no])
])
AH_TEMPLATE([HAVE_]translit($2, [ a-z], [_A-Z]),
[Define to 1 if ]$2[ is defined by a system header])
if test $xsh_cv_type_exists_[]translit($2, [ ], [_]) = yes; then
  AC_DEFINE([HAVE_]translit($2, [ a-z], [_A-Z]))
fi
])

dnl
dnl xsh_STRUCT_MEMBER(#includes, type name, member name)
dnl   Check whether a specified aggregate type exists and contains
dnl   a specified member.
dnl

AC_DEFUN(xsh_STRUCT_MEMBER,
[AC_CACHE_CHECK([for $3 in $2], [xsh_cv_struct_member_[]translit($2, [ ], [_])_$3],
[AC_COMPILE_IFELSE([AC_LANG_PROGRAM([[$1]], [[$2 testvar; testvar.$3;]])],
[xsh_cv_struct_member_[]translit($2, [ ], [_])_$3=yes],
[xsh_cv_struct_member_[]translit($2, [ ], [_])_$3=no])
])
AH_TEMPLATE([HAVE_]translit($2_$3, [ a-z], [_A-Z]),
[Define if your system's ]$2[ has a member named ]$3[.])
if test $xsh_cv_struct_member_[]translit($2, [ ], [_])_$3 = yes; then
  AC_DEFINE([HAVE_]translit($2_$3, [ a-z], [_A-Z]))
fi
])

dnl
dnl xsh_ARG_PROGRAM
dnl   Handle AC_ARG_PROGRAM substitutions into other xsh configure macros.
dnl   After processing this macro, the configure script may refer to
dnl   and $txsh_name, and @txsh@ is defined for make substitutions.
dnl

AC_DEFUN(xsh_ARG_PROGRAM,
[AC_ARG_PROGRAM
# Un-double any \ or $ (doubled by AC_ARG_PROGRAM).
cat <<\EOF_SED > conftestsed
s,\\\\,\\,g; s,\$\$,$,g
EOF_SED
xsh_transform_name=`echo "${program_transform_name}" | sed -f conftestsed`
rm -f conftestsed
txsh_name=`echo xsh | sed -e "${xsh_transform_name}"`
# Double any \ or $ in the transformed name that results.
cat <<\EOF_SED >> conftestsed
s,\\,\\\\,g; s,\$,$$,g
EOF_SED
txsh=`echo ${txsh_name} | sed -f conftestsed`
rm -f conftestsed
AC_SUBST(txsh)dnl
])

AC_DEFUN(xsh_COMPILE_FLAGS,
    [AC_ARG_ENABLE(cppflags,
	AS_HELP_STRING([--enable-cppflags=...], [specify C preprocessor flags]),
	if test "$enableval" = "yes"
	then CPPFLAGS="$1"
	else CPPFLAGS="$enable_cppflags"
	fi)
    AC_ARG_ENABLE(cflags,
	AS_HELP_STRING([--enable-cflags=...], [specify C compiler flags]),
	if test "$enableval" = "yes"
	then CFLAGS="$2"
	else CFLAGS="$enable_cflags"
	fi)
    AC_ARG_ENABLE(ldflags,
	AS_HELP_STRING([--enable-ldflags=...], [specify linker flags]),
	if test "$enableval" = "yes"
	then LDFLAGS="$3"
	else LDFLAGS="$enable_ldflags"
	fi)
    AC_ARG_ENABLE(libs,
	AS_HELP_STRING([--enable-libs=...], [specify link libraries]),
	if test "$enableval" = "yes"
	then LIBS="$4"
	else LIBS="$enable_libs"
	fi)])

dnl 
dnl xsh_CHECK_SOCKLEN_T
dnl
dnl	check type of third argument of some network functions; currently
dnl	tested are size_t *, unsigned long *, int *.
dnl     call the result ZSOCKLEN_T since some systems have SOCKLEN_T already
dnl
AC_DEFUN([xsh_CHECK_SOCKLEN_T],[
  AC_CACHE_CHECK(
    [base type of the third argument to accept],
    [xsh_cv_type_socklen_t],
    [xsh_cv_type_socklen_t=
    for xsh_type in socklen_t int "unsigned long" size_t ; do
      AC_COMPILE_IFELSE([AC_LANG_PROGRAM(
        [[#include <sys/types.h>
          #include <sys/socket.h>]],
        [[extern int accept (int, struct sockaddr *, $xsh_type *);]])],
        [xsh_cv_type_socklen_t="$xsh_type"; break],
        []
      )
    done
    if test -z "$xsh_cv_type_socklen_t"; then
      xsh_cv_type_socklen_t=int
    fi]
  )
  AC_DEFINE_UNQUOTED([ZSOCKLEN_T], [$xsh_cv_type_socklen_t],
  [Define to the base type of the third argument of accept])]
)

dnl Check for limit $1 e.g. RLIMIT_RSS.
AC_DEFUN(xsh_LIMIT_PRESENT,
[AH_TEMPLATE([HAVE_]$1,
[Define to 1 if ]$1[ is present (whether or not as a macro).])
AC_CACHE_CHECK([for limit $1],
xsh_cv_have_$1,
[AC_COMPILE_IFELSE([AC_LANG_PROGRAM([[
#include <sys/types.h>
#ifdef HAVE_SYS_TIME_H
#include <sys/time.h>
#endif
#include <sys/resource.h>]],
[[$1]])],
  [xsh_cv_have_$1=yes],
  [xsh_cv_have_$1=no])])

if test $xsh_cv_have_$1 = yes; then
  AC_DEFINE(HAVE_$1)
fi])

dnl Check whether rlmit $1, e.g. AS, is the same as rlmit $3, e.g. VMEM.
dnl $2 is lowercase $1, $4 is lowercase $3.
AC_DEFUN(xsh_LIMITS_EQUAL,
[AH_TEMPLATE([RLIMIT_]$1[_IS_]$3,
[Define to 1 if RLIMIT_]$1[ and RLIMIT_]$3[ both exist and are equal.])
AC_CACHE_CHECK([if RLIMIT_]$1[ and RLIMIT_]$3[ are the same],
xsh_cv_rlimit_$2_is_$4,
[AC_COMPILE_IFELSE([AC_LANG_PROGRAM([[
#include <sys/types.h>
#ifdef HAVE_SYS_TIME_H
#include <sys/time.h>
#endif
#include <sys/resource.h>]],
[[static char x[(RLIMIT_$1 == RLIMIT_$3)? 1 : -1]]])],
  [xsh_cv_rlimit_$2_is_$4=yes],
  [xsh_cv_rlimit_$2_is_$4=no])])
if test x$xsh_cv_rlimit_$2_is_$4 = xyes; then
  AC_DEFINE(RLIMIT_$1_IS_$3)
fi])
