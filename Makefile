PREFIX=/usr/local
BINDIR=$(PREFIX)/bin

all:
	@echo "Run \"sudo make install\" to install cronplan"

install:
	install -m 0755 cronplan.sh $(BINDIR)/cronplan
