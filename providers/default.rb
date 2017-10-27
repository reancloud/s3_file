require 'digest/md5'
require 'json'

use_inline_resources

action :create do
  @run_context.include_recipe 's3_file::dependencies'
  client = S3FileLib::client
  download = true

  # handle key specified without leading slash, and support URL encoding when necessary.
  remote_path = ::File.join('', new_resource.remote_path).split('/').map{|x| CGI.escape(x)}.join('/')

  # we need credentials to be mutable
  aws_access_key_id = new_resource.aws_access_key_id
  aws_secret_access_key = new_resource.aws_secret_access_key
  aws_region = new_resource.aws_region
  token = new_resource.token
  decryption_key = new_resource.decryption_key

  # if credentials not set, try instance profile
  if aws_access_key_id.nil? && aws_secret_access_key.nil? && token.nil?
    instance_profile_base_url = 'http://169.254.169.254/latest/meta-data/iam/security-credentials/'
    begin
      instance_profiles = client.get(instance_profile_base_url)
    rescue client::ResourceNotFound, Errno::ETIMEDOUT # we can either 404 on an EC2 instance, or timeout on non-EC2
      raise ArgumentError.new 'No credentials provided and no instance profile on this machine.'
    end
    instance_profile_name = instance_profiles.split.first
    instance_profile = JSON.load(client.get(instance_profile_base_url + instance_profile_name))

    aws_access_key_id = instance_profile['AccessKeyId']
    aws_secret_access_key = instance_profile['SecretAccessKey']
    token = instance_profile['Token']
      
    # now try to auto-detect the region from the instance
    if aws_region.nil?
      dynamic_doc_base_url = 'http://169.254.169.254/latest/dynamic/instance-identity/document'
      begin
        dynamic_doc = JSON.load(client.get(dynamic_doc_base_url))
        aws_region = dynamic_doc['region']
      rescue Exception => e
        Chef::Log.debug "Unable to auto-detect region from instance-identity document: #{e.message}"
      end
    end
  end
    
  f = file new_resource.path do
    action :create
    owner new_resource.owner || ENV['user']
    group new_resource.group || ENV['user']
    mode new_resource.mode || '0644'
  end

  new_resource.updated_by_last_action(download || f.updated_by_last_action?)
end
