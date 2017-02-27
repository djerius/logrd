#                                               -*- Autoconf -*-
# Process this file with autoconf to produce a configure script.
AC_PREREQ([2.57])

AC_INIT([logrd],[0.04],[opticsoft@head.cfa.harvard.edu],[logrd])
AC_CONFIG_SRCDIR([src/logrd.bash])
AC_CONFIG_MACRO_DIR([m4])
AC_CONFIG_AUX_DIR([build-aux])
AC_REQUIRE_AUX_FILE([tap-driver.sh])
AM_INIT_AUTOMAKE([ check-news subdir-objects ])

# Checks for programs.
AC_PROG_INSTALL
AC_PROG_MKDIR_P

MST_BATS
MST_POD_GEN_DOCS

# Checks for library functions.
AC_CONFIG_FILES([Makefile])

AC_OUTPUT
