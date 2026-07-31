STANDARD=-out:source3.exe
LINT=-vet -strict-style
SANITIZE=-sanitize:address

DBG_OPTS=-debug
# $(SANITIZE) -stack-protector:all
OPTS=$(LINT) $(STANDARD) -thread-count:2 -subsystem:windows

rdbg:
	odin build src $(OPTS) $(DBG_OPTS)
	raddbg .\source3.exe
dbg:
	odin run src $(OPTS) $(DBG_OPTS)
dbgb:
	odin build src $(OPTS) $(DBG_OPTS)
dbgfast:
	odin run src -debug -thread-count:8 $(STANDARD)
build:
	odin build src $(OPTS) $(DBG_OPTS)
run:
	.\src
release:
	odin build src -o:speed $(OPTS)
