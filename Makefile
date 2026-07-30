LINT=-vet -strict-style
SANITIZE=-sanitize:address
DBG_OPTS=$(SANITIZE) -debug -stack-protector:all
OPTS=$(LINT) -thread-count:2 -out:source3.exe

dbg:
	odin run src $(OPTS) $(DBG_OPTS)
build:
	odin build src $(OPTS) $(DBG_OPTS)
run:
	.\src
release:
	odin build src -o:speed $(OPTS)
