# if building from a dist tarball, bats can't find itself as the
# Makefile turns the symbolic which is bats/bin/bats ->
# ../libexec/bats into a hard link. therefore, add libexec path

AM_TESTS_ENVIRONMENT += PATH=$(abs_top_srcdir)/%D%/bats/bin:%D%/bats/bin:$(abs_top_srcdir)/%D%/bats/libexec:%D%/bats/libexec:${PATH};

EXTRA_DIST += %D%/bats

TEST_EXTENSIONS += .bats

BATS_LOG_DRIVER =                                                         \
        env AM_TAP_AWK='$(AWK)' $(SHELL)                                  \
        $(abs_top_srcdir)/build-aux/tap-driver.sh

