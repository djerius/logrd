include %D%/bats.mk

# so we can find logrd.bash 
AM_TESTS_ENVIRONMENT += PATH=$(abs_top_srcdir)/src:${PATH};

TESTS			+= %D%/options.bats %D%/streams.bats %D%/logging.bats

EXTRA_DIST              +=			\
			$(TESTS)		\
			%D%/functions.bash	\
			%D%/bats

