top:; @date

. := $(or $(filter staff, $(shell groups)), $(error $(USER) not in group staff))

name := propagate-date
installed := /usr/local/bin/$(name)
install: $(installed);
.PHONY: install
$(installed): $(name).pl; install $< $@
