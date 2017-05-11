top:; @date

SHELL := $(shell which bash)

. := $(or $(filter $(MAKECMDGOALS), staff), $(filter staff, $(shell groups)), $(error $(USER) not in group staff (make staff -n)))

name := propagate-date
installed := /usr/local/bin/$(name)
install: $(installed);
.PHONY: install
$(installed): $(name).pl; install $< $@

# newgrp does « execl(shell, shell, (char *)0); »
# So, we can't automate the sequence « newgrp staff; newgrp »

staff := getent group staff > /dev/null || sudo adduser $(USER) staff;
staff += groups | grep staff > /dev/null || echo -e "source <(echo 'exec newgrp staff')\nsource <(echo 'exec newgrp')";
staff:; @$($@)
