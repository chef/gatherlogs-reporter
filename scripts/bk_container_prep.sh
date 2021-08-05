# Script to get a container ready to run the tests in BuildKite
echo -n "Ruby version: "
ruby --version
echo -n "Gem version: "
gem --version
# Ruby version is new enough that we don't need this now
#gem uninstall bundler -a -x || true
#gem install bundler -v 2.0.1
bundle --version
rm -f .bundle/config
