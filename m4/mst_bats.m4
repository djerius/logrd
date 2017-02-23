# unpack bats source
# serial 2

# MST_BATS
#----------
AC_DEFUN([MST_BATS],
[
AC_ARG_WITH( [bats],
             [AS_HELP_STRING([--with-bats=ARG],
                             [ARG is path to bats archive @<:@default=use bundled version@:>@])],
             [],[with_bats=no]
           )
AC_CACHE_CHECK([for BATS],[mst_cv_prog_bats],
[
  AS_IF( [test "$with_bats" = ""],
          [AC_MSG_ERROR([--with-bats requires an argument])],
	 [ test "$with_bats" = no],
	 [ AC_CHECK_FILE([$srcdir/tests/bats/bin/bats],
		    [mst_cv_prog_bats=$srcdir/tests/bats/bin/bats],
		    [AC_CHECK_FILE([tests/bats/bin/bats],
				   [mst_cv_prog_bats=tests/bats/bin/bats],
				   [AC_MSG_ERROR([bats is not bundled; please specify it with --with-bats (see https://github.com/sstephenson/bats/releases)])]
				   )
		    ]
           )
           AS_EXECUTABLE_P([$mst_cv_prog_bats]),
           AC_MSG_NOTICE([using bundled bats])
         ],
         [
	   AC_MSG_NOTICE([trying bats distribution $with_bats])
	   AC_CHECK_FILE([$with_bats],
			 [],
			 [AC_MSG_ERROR(cannot find $with_bats)]
			)

	   AS_CASE( [$with_bats],
		   [*.tar.gz],
		   [
		       AC_PATH_PROG([TAR],[tar],[no])
		       test "$TAR" = no && \
			   AC_MSG_ERROR([tar not found; unable to extract bats])
		       AC_MSG_NOTICE([unpacking $with_bats])
		       AS_MKDIR_P([tests/bats])

		       # extract just the bits of bats we need.  GNU vs BSD
		       # tar are different enough that it's easier to extract
		       # everything and copy things over.  For history: GNU
		       # tar doesn't have --include, doesn't like it if
		       # directories are specified before their contents
		       (
			 set -e
			 AS_TMPDIR([mst_bats_])
			 trap "rm -rf $tmp" EXIT

			 $TAR -C $tmp --strip-components 1 -xf $with_bats

			 cp -a \
			    $tmp/LICENSE \
			    $tmp/README.md \
			    $tmp/bin \
			    $tmp/libexec \
			    tests/bats
		       )

		       test $? -ne 0 && AC_MSG_ERROR([error extracting bats])
		       mst_cv_prog_bats=tests/bats/bin/bats
		   ],
		   [
		       AC_MSG_ERROR([do not know how to unpack bats archive $with_bats])
		   ]
	   )
        ]
  )
])
AC_SUBST([BATS],[$mst_cv_prog_bats])
])
