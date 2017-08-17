help:
	@echo "submodules    Get submodules"
	@echo "update        Checkout master, get submodules and pull all formulas"
	@echo "release       Make new major release of all formulas"
	@echo "mrconfig      Re-generate .mrconfig with all formulas on Github"
	@echo "html          Build html documentation"
	@echo "pdf           Build pdf documentation"
	@echo "remote_gerrit Add git remote gerrit"
	@echo "remote_github Add git remote github"

pull:
	git pull --rebase

submodules: pull
	git submodule init
	git submodule update

update: submodules
	(for formula in formulas/*; do FORMULA=`basename $$formula` && cd $$formula && git remote set-url --push origin git@github.com:salt-formulas/salt-formula-$$FORMULA.git && cd ../..; done)
	mr --trust-all -j4 run git checkout master
	mr --trust-all -j4 update

release:
	mr --trust-all -j4 run make release-major

mrconfig:
	./scripts/update_mrconfig.py

muconfig:
	mu group add salt-formulas --empty
	mu register $(FORKED_FORMULAS_DIR)/*

html:
	make -C doc html

pdf:
	make -C doc latexpdf

FORKED_FORMULAS_DIR=formulas
FORMULAS=`python3 -c 'import sys; sys.path.append("scripts");from update_mrconfig import *; print(*get_org_repos(make_github_agent(), "salt-formulas"), sep="\n")'| egrep 'salt-formula-' | sed 's/salt-formula-//'`

scripts_prerequisites:
	pip3 install -r scripts/requirements.txt

list: scripts_prerequisites
	@echo $(FORMULAS)

update_forks:
	@mkdir -p $(FORKED_FORMULAS_DIR)
	@for FORMULA in $(FORMULAS) ; do\
     echo "## Forking: $$FORMULA";\
     test -e $(FORKED_FORMULAS_DIR)/$$FORMULA || git clone https://github.com/salt-formulas/salt-formula-$$FORMULA.git $(FORKED_FORMULAS_DIR)/$$FORMULA;\
   done;


GERRIT_REMOTE_URI=gerrit.mcp.mirantis.net:29418/salt-formulas
remote_gerrit: remote_gerrit_s
remote_gerrit_s: FORMULAS_DIR=formulas
remote_gerrit_s: remote_gerrit_add
remote_gerrit_f: FORMULAS_DIR=$(FORKED_FORMULAS_DIR)
remote_gerrit_f: remote_gerrit_add

remote_gerrit_add:
	@#(for formula in $(FORMULAS_DIR)/*; do FORMULA=`basename $$formula` && cd $$formula && git remote remove gerrit || true && cd ../.. ; done)
	@mkdir -p $(FORMULAS_DIR)
	@ID=$${GERRIT_USERNAME:-$$USER};\
   for FORMULA in `ls $(FORMULAS_DIR)/`; do\
     cd $(FORMULAS_DIR)/$$FORMULA > /dev/null;\
     if ! git remote | grep gerrit 2>&1 > /dev/null ; then\
       git remote add gerrit ssh://$$ID@$(GERRIT_REMOTE_URI)/$$FORMULA;\
     fi;\
     cd - > /dev/null;\
     done;

remote_github: remote_github_s
remote_github_s: FORMULAS_DIR=formulas
remote_github_s: remote_github_add
remote_github_f: FORMULAS_DIR=$(FORKED_FORMULAS_DIR)
remote_github_f: remote_github_add

remote_github_add:
	@mkdir -p $(FORMULAS_DIR)
	@ID=$${GITHUB_USERNAME:-$$USER};\
   for FORMULA in `ls $(FORMULAS_DIR)/`; do\
     cd $(FORMULAS_DIR)/$$FORMULA > /dev/null;\
     if ! git remote | grep $$ID 2>&1 > /dev/null ; then\
       git remote add $$ID git://github.com/$$ID/salt-formula-$$FORMULA;\
     fi;\
     cd - > /dev/null;\
     done;
