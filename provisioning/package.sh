rm -rf build && mkdir build

GEM_OUTPUT="vendor/bundle"

rm -rf "$GEM_OUTPUT" && mkdir -p "$GEM_OUTPUT"

echo "Installing dependencies to $GEM_OUTPUT"

# Build dependencies:
gem update --system
gem install bundler

bundle config set --local path "$GEM_OUTPUT"
bundle install
bundle install --deployment

# Move required application files into build:
zip -r build/lambda-deployment.zip app.rb lib vendor
