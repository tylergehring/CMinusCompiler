SUBMISSION = assignment1.tar
SOURCES = parser.l parser.y parser.scantype.h makefile

.PHONY: all clean submission

all:
	$(MAKE) -C CMinusCompiler
	cp CMinusCompiler/c- c-

clean:
	$(MAKE) -C CMinusCompiler clean
	rm -f c- $(SUBMISSION)

submission:
	tar -cf $(SUBMISSION) -C CMinusCompiler $(SOURCES)