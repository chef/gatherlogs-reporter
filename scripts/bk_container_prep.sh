# Script to get a container ready to run the tests in BuildKite

gem --version
gem uninstall bundler -a -x || true
gem install bundler -v 2.0.1
bundle --version
rm -f .bundle/config
