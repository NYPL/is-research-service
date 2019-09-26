# is-research-service

This is a Ruby app deployed as an AWS Lambda behind API Gateway to serve:

``GET /api/v0.1/items/{nypl_source}/{id}/is-research``

## Setup
### Installation

``bundle install; bundle install --deployment``

### Config
All config is in sam.[ENVIRONMENT].yml templates, encrypted as necessary.

## Contributing
### Running Events Locally
The following will invoke the lambda against the sample event.json

``sam local invoke --event event.json --region us-east-1 --template sam.local.yml --profile [aws profile]``

### Running Server Locally
To run the server locally:

``sam local start-api --region us-east-1 --template sam.local.yml --profile [aws profile]``

### Gemfile Changes
Given that gems are installed with the --deployment flag, Bundler will complain if you make changes to the Gemfile. To make changes to the Gemfile, exit deployment mode:

``bundle install --no-deployment``

## Testing

``bundle exec rspec -fd``
