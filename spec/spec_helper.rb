require 'json'
require 'nypl_log_formatter'

require_relative '../lib/platform_api_client'
require_relative '../lib/kms_client'
require_relative '../lib/item'
require_relative '../lib/nypl_core'
require_relative '../app'

ENV['LOG_LEVEL'] ||= 'error'
ENV['APP_ENV'] = 'test'
