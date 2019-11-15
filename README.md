# is-research-service

This is a Ruby app deployed as an AWS Lambda behind API Gateway to serve:

``GET /api/v0.1/items/{nyplSource}/{id}/is-research``

The business logic implemented in this code base for determining if an item or bib is research or circulating is documented here:

https://github.com/NYPL/nypl-core/blob/master/vocabularies/business-logic/nyplResearchItemAndBibDetermination.md

## Setup
### Installation

``bundle install; bundle install --deployment``

If you get an error ``You must use Bundler 2 or greater with this lockfile.``

run

``gem install bundler -v 2.0.2``

### Config
All config is in sam.[ENVIRONMENT].yml templates, encrypted as necessary.

## Contributing
### Git Workflow
 * Cut branches from `development`.
 * Create PR against `development`.
 * After review, PR author merges.
 * Merge `development` > `qa`
 * Merge `qa` > `master`
 * Tag version bump in `master`

### Running Events Locally
The following will invoke the lambda against the sample event.json

``sam local invoke --event [event] --region us-east-1 --template sam.local.yml --profile [aws profile]``

#### Events
 * `event-is_research_false.json`
 * `event-not_found.json`
 * `event-swagger.json`


### Running Server Locally
To run the server locally:

``sam local start-api --region us-east-1 --template sam.local.yml --profile [aws profile]``

### Gemfile Changes
Given that gems are installed with the --deployment flag, Bundler will complain if you make changes to the Gemfile. To make changes to the Gemfile, exit deployment mode:

``bundle install --no-deployment``

## Testing

``bundle exec rspec -fd``

## Deploy
Deployments are entirely handled by Travis-ci.com. To deploy to development, qa, or production, commit code to the development, qa, and master branches on origin, respectively.
