# This is a GNU-make file made
# for automatic testing to validate
# the main executable file.

MAKEFLAGS = -r

.PHONY: all display clean distclean

SCRIPT_DIR = .

all:

display:
	@echo ${${VAR}}

clean: clean-tests

distclean: clean

# Declaring variables.
TEST_DIR = tests
TEST_CASE_DIR = ${TEST_DIR}/cases
TEST_DIFF_DIR = ${TEST_DIR}/outputs
TEST_OUTP_DIR = ${TEST_DIR}/outputs

TEST_INPUTS = $(wildcard ${TEST_CASE_DIR}/*.inp)
TEST_OUTPS = $(sort $(TEST_INPUTS:${TEST_CASE_DIR}/%.inp=\
	       ${TEST_OUTP_DIR}/%.out))
TEST_DIFFS = $(sort $(TEST_INPUTS:${TEST_CASE_DIR}/%.inp=\
               ${TEST_DIFF_DIR}/%.diff))

# Section for test dependencies.
TEST_DEPENDENCIES = .test_depend

include ${TEST_DEPENDENCIES}

${TEST_DEPENDENCIES}: ${TEST_INPUTS}
	@find tests/cases/ -name "*.inp" \
        | sed 's|/cases/|/outputs/|; s|\.inp$$|\.diff|' \
        | awk '{\
              	pgm = $$1; \
                sub("${TEST_OUTP_DIR}/","",pgm); \
                sub("_[0-9]*\..*$$","",pgm); \
                print $$1 ": " "${SCRIPT_DIR}/"pgm \
                }' \
	| sort \
        > $@

# Automatic testing.
.PHONY: test clean-tests

test: ${TEST_OUTPS} ${TEST_DIFFS}

# Generating output files.
${TEST_OUTP_DIR}/%.out:
	@${SCRIPT_DIR}/$(shell echo $* | sed 's/\(.*\)_[0-9]*/\1/') \
	${TEST_CASE_DIR}/$*.inp > $@

# Generating diff files.
${TEST_DIFF_DIR}/%.diff: $(TEST_CASE_DIR)/%.inp ${TEST_OUTP_DIR}/%.out
	@echo -n $*": "
	@${SCRIPT_DIR}/$(shell echo $* | sed 's/\(.*\)_[0-9]*/\1/') \
	$< 2>&1 | diff - $(word 2, $^) > $@; \
	if [ $$? -eq 0 ]; then echo "OK"; else echo "FAILED"; cat $@; fi

clean-tests:
	rm -f ${TEST_DIFFS}
	rm -f ${TEST_DEPENDENCIES}
	
reproduce-data:
	cd ./REST && ./get-virus-data
	./batch_processing > capsid_volumes.tab
