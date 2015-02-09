RAILS_ENV = test
BUNDLE = RAILS_ENV=${RAILS_ENV} bundle
BUNDLE_OPTIONS = -j 2
RSPEC = rspec

all: test

test: config/database bundler/install
	${BUNDLE} exec ${APPRAISAL} ${RSPEC} spec 2>&1

config/database:
	touch spec/internal/config/database.yml
	echo 'test:' >> spec/internal/config/database.yml
	echo '  adapter: postgresql' >> spec/internal/config/database.yml
	echo '  database: docker' >> spec/internal/config/database.yml
	echo '  username: docker' >> spec/internal/config/database.yml
	echo '  host: localhost' >> spec/internal/config/database.yml
	echo '  min_messages: warning' >> spec/internal/config/database.yml

bundler/install:
	if ! gem list bundler -i > /dev/null; then \
	  gem install bundler; \
	fi
	${BUNDLE} install ${BUNDLE_OPTIONS}
