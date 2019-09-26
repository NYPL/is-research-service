require 'json'
require 'nypl_log_formatter'

require_relative '../lib/platform_api_client'
require_relative '../lib/kms_client'
require_relative '../lib/item'
require_relative '../lib/nypl_core'
require_relative '../app.rb'

$kms_client = KmsClient.aws_kms_client.stub_responses(:decrypt, -> (context) {
  # "Decrypt" by subbing "encrypted" with "decrypted" in string:
  { plaintext: context.params[:ciphertext_blob].gsub('encrypted', 'decrypted') }
})

$logger = NyplLogFormatter.new(STDOUT, level: ENV['LOG_LEVEL'] || 'info')
