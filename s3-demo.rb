# s3-demo.rb

require 'aws-sdk'
require 'securerandom'

aws_config = {
  :access_key => ENV['AWS_ACCESS_KEY_ID'] || 'your-access-key-here',
  :secret_key => ENV['AWS_SECRET_ACCESS_KEY'] || 'your-secret-key-here',
  :region => ENV['AWS_REGION'] || 'your-prefered-region-here'
}
aws_credentials = Aws::Credentials.new( aws_config[:access_key], aws_config[:secret_key] )

begin

  _s3client = Aws::S3::Client.new( credentials: aws_credentials, region: aws_config[:region] )
  s3client = Aws::S3::Resource.new( client: _s3client )
  _object = s3client.bucket('some-bucket').object('test.txt')
  _object.upload_file( File.expand_path('../test.txt', __FILE__) )
  _object.wait_until_exists { |waiter|
    waiter.interval = 10
  }

  cfclient = Aws::CloudFront::Client.new( credentials: aws_credentials, region: aws_config[:region] )
  _response = cfclient.create_invalidation(
    distribution_id: "your-distribution-id",
      invalidation_batch: {
        paths: {
          quantity: 1,
          items: ["test.txt"]
        },
        caller_reference: SecureRandom.uuid
      }
  )
  puts _response

# Service errors
rescue Aws::S3::Errors::ServiceError => ex
  puts "S3ERROR!! #{ex.message}"
  puts ex.backtrace.join("\n")
# Normal Errors
rescue => ex
  puts ex.message
  puts ex.backtrace.join("\n")
end
