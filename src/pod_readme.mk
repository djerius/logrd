#============================================================================
# pod_readme.mk

POD_README_MK =

# prerequisite packages
CREATE_AM_MACROS_MK +=


#----------------------------------------
# caller must define these
#
# A simple list of POD files to process.  Just the basename's, no suffix.
# No Make Magic. Only the first is used for README
PODS +=

# the suffix of the files containing POD
POD_SFX +=

# Note that this implies that all pod source files have the same suffix
# If this is not the case, add rules to create .pod files like so:
#
# %.pod : %.xx
#	podselect %< > $@
#
# and set POD_SFX to .pod.  Just make sure that %.xx is an invariant
# file (i.e. not something created from a .in file).  Usually just using
# the .in file as the source is pretty safe.

# if the caller is using this file directly (and not going through prog_all.mk)
# add
#
#   EXTRA_DIST += $(PODS:%=%$(POD_SFX))


# Only attempt to generate documentation if we can.  Always
# distribute it; this will cause failure on devel systems without
# pod2readme, but that's ok.


if MST_POD_GEN_DOCS_README

SUFFIXES += $(POD_SFX)

README : $(word 1,$(PODS))$(POD_SFX)
	pod2readme $< $@

else !MST_POD_GEN_DOCS_README

# can't create documentation.  for end user, the distributed
# documentation will get installed.

# for maintainer, must create fake docs or make will fail,
# but don't distribute


README:
	touch $@

dist-hook::
	echo >&2 "Cannot create distribution as cannot create README documentation"
	echo >&2 "Install pod2readme (from CPAN)"
	false

endif !MST_POD_GEN_DOCS_README

BUILT_SOURCES += README
