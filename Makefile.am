include create_am_macros.mk

ACLOCAL_AMFLAGS = -I m4 --install

MAINTAINERCLEANFILES	+= \
			Makefile.in	\
			aclocal.m4	\
			compile		\
			config.guess	\
			config.h.in	\
			config.sub	\
			configure	\
			depcomp		\
			install-sh	\
			ltmain.sh	\
			missing		\
			mkinstalldirs

include src/Makefile.am
include tests/Makefile.am
