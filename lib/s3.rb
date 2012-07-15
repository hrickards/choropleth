require 'psych'
require 'aws/s3'

module ChoroplethGenerator
  BUCKET_NAME = 'choropleth'

  class S3
    def initialize
      auth_options = Psych.load File.open('s3.yaml', 'r').read
      AWS::S3::Base.establish_connection! :access_key_id => auth_options['access_key_id'], :secret_access_key => auth_options['secret_access_key']
    end

    # Upload text into a file named filename, unless filename already exists
    def upload_if_not_present(text, filename)
      if not AWS::S3::S3Object.exists? filename, BUCKET_NAME
        AWS::S3::S3Object.store filename, text, BUCKET_NAME, :access => :public_read
      end
    end
    
    # Get the S3 url for a given filename
    def self.get_url(filename)
      "http://#{BUCKET_NAME}.#{AWS::S3::DEFAULT_HOST}/#{filename}"
    end
  end
end
