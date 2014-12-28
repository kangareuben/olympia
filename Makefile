.PHONY: help docs test test_es test_no_es test_force_db tdd test_failed initialize_db populate_data update_code update_deps update_db update_assets full_init full_update reindex flake8
NUM_ADDONS=10
NUM_THEMES=$(NUM_ADDONS)

UNAME_S := $(shell uname -s)

# If you're using docker and fig, you can use this Makefile to run commands in
# your docker images by setting the FIG_PREFIX environment variable to:
# FIG_PREFIX="fig run --rm web"

help:
	@echo "Please use 'make <target>' where <target> is one of"
	@echo "  docs              to builds the docs for Zamboni"
	@echo "  test              to run all the test suite"
	@echo "  test_force_db     to run all the test suite with a new database"
	@echo "  tdd               to run all the test suite, but stop on the first error"
	@echo "  test_failed       to rerun the failed tests from the previous run"
	@echo "  initialize_db     to create a new database"
	@echo "  populate_data     to populate a new database"
	@echo "  update_code       to update the git repository"
	@echo "  update_deps       to update the python and npm dependencies"
	@echo "  update_db         to run the database migrations"
	@echo "  full_init         to init the code, the dependencies and the database"
	@echo "  full_update       to update the code, the dependencies and the database"
	@echo "  reindex           to reindex everything in elasticsearch, for AMO"
	@echo "  flake8            to run the flake8 linter"
	@echo "Check the Makefile  to know exactly what each target is doing. If you see a "

docs:
	$(FIG_PREFIX) $(MAKE) -C docs html

test:
	$(FIG_PREFIX) py.test $(ARGS)

test_es:
	$(FIG_PREFIX) py.test -m es_tests $(ARGS)

test_no_es:
	$(FIG_PREFIX) py.test -m "not es_tests" $(ARGS)

test_force_db:
	$(FIG_PREFIX) py.test --create-db $(ARGS)

tdd:
	$(FIG_PREFIX) py.test -x --pdb $(ARGS)

test_failed:
	$(FIG_PREFIX) py.test --lf $(ARGS)

initialize_db:
	$(FIG_PREFIX) python manage.py reset_db
	$(FIG_PREFIX) python manage.py syncdb --noinput
	$(FIG_PREFIX) python manage.py loaddata initial.json
	$(FIG_PREFIX) python manage.py import_prod_versions
	$(FIG_PREFIX) schematic --fake migrations/
	$(FIG_PREFIX) python manage.py createsuperuser

populate_data:
	$(FIG_PREFIX) python manage.py generate_addons --app firefox $(NUM_ADDONS)
	$(FIG_PREFIX) python manage.py generate_addons --app thunderbird $(NUM_ADDONS)
	$(FIG_PREFIX) python manage.py generate_addons --app android $(NUM_ADDONS)
	$(FIG_PREFIX) python manage.py generate_addons --app seamonkey $(NUM_ADDONS)
	$(FIG_PREFIX) python manage.py generate_themes $(NUM_THEMES)
	$(FIG_PREFIX) python manage.py reindex --wipe --force

update_code:
	$(FIG_PREFIX) git checkout master && git pull

update_deps:
ifeq ($(UNAME_S),Linux)
	$(FIG_PREFIX) DEB_HOST_MULTIARCH=x86_64-linux-gnu pip install -I --exists-action=w "git+git://anonscm.debian.org/collab-maint/m2crypto.git@debian/0.21.1-3#egg=M2Crypto"
else
	$(FIG_PREFIX) pip install --find-links https://pyrepo.addons.mozilla.org/ --exists-action=w --download-cache=/tmp/pip-cache "m2crypto==0.21.1"
endif

	$(FIG_PREFIX) pip install --no-deps --exists-action=w --download-cache=/tmp/pip-cache -r requirements/dev.txt --find-links https://pyrepo.addons.mozilla.org/
	$(FIG_PREFIX) npm install

update_db:
	$(FIG_PREFIX) schematic migrations

update_assets:
	$(FIG_PREFIX) python manage.py compress_assets
	$(FIG_PREFIX) python manage.py collectstatic --noinput

full_init: update_deps initialize_db populate_data update_assets

full_update: update_code update_deps update_db update_assets

reindex:
	$(FIG_PREFIX) python manage.py reindex $(ARGS)

flake8:
	$(FIG_PREFIX) flake8 --ignore=E265 --exclude=services,wsgi,docs,node_modules,build*.py .
