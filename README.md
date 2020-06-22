# is-research-service

[![Build Status](https://travis-ci.com/NYPL/is-research-service.svg?branch=master)](https://travis-ci.com/NYPL/is-research-service) 

This is a Ruby app deployed as an AWS Lambda behind API Gateway to serve:

``GET /api/v0.1/items/{nyplSource}/{id}/is-research``

The `is-research-layer` directory corresponds to the Lambda Layer used for the forthcoming `SubjectHeadingPoster`. Instructions for updating and redeploying the layer are below.

The business logic implemented in this code base for determining if an item or bib is research or circulating is documented here:

https://github.com/NYPL/nypl-core/blob/master/vocabularies/business-logic/nyplResearchItemAndBibDetermination.md

## Setup
### Installation

``bundle install; bundle install --deployment``

If you get the error ``You must use Bundler 2 or greater with this lockfile.`` run

``gem install bundler -v 2.0.2``

### Config
All config is in `sam.[ENVIRONMENT].yml` templates, encrypted as necessary.

## Contributing
### Git Workflow
 * Cut branches from `development`.
 * Create PR against `development`.
 * After review, PR author merges.
 * Merge `development` > `qa`
 * Merge `qa` > `master`
 * Tag version bump in `master`

### Updating Lambda Layer
 * Once any change to the files within `is-research-layer` have been developed and reviewed, from the main directory, run

 ``zip -r is-research-layer is-research-layer/*``

 * Create a new version of the layer from the AWS console under Lambda service.
 * Update Lambdas that pull in this layer by changing the version number in the SAM template.
  * Lambdas using the "isResearchLayer":
    * `SubjectHeadingPoster-qa` (forthcoming)

### Running Events Locally
The following will invoke the lambda against various mock events. Replace `[event]` with one of the mock events listed below.

``sam local invoke --event [event] --region us-east-1 --template sam.local.yml --profile [aws profile]``

#### Events
 * `event-bib_is_research_true.json`
 * `event-item_is_research_true.json`
 * `event-item_is_research_false.json`
 * `event-item_not_found.json`
 * `event-swagger.json`


### Running Server Locally
To run the server locally:

``sam local start-api --template sam.local.yml``

### Gemfile Changes
Given that gems are installed with the --deployment flag, Bundler will complain if you make changes to the Gemfile. To make changes to the Gemfile, exit deployment mode:

``bundle install --no-deployment``

## Testing

``bundle exec rspec -fd``
Make sure to also run a test event, as described above as a form of end-to-end testing.

## Scripts
The `scripts` directory contains code used for a one time processing of an export of the `itemservice` sql database run locally. The scripts will not be actively maintained with the codebase. They are preserved for reference purposes.

## Deploy
Deployments are entirely handled by Travis-ci.com. To deploy to development, qa, or production, commit code to the development, qa, and master branches on origin, respectively.
