case node['platform_family']
when 'debian', 'rhel', 'centos', 'amazon'
  %w(gcc gcc-c++).each do |pkg|
    package pkg
  end.run_action(:install)
end

chef_gem 'mime-types' do
  version node['s3_file']['mime-types']['version']
  action :install
  compile_time true if Chef::Resource::ChefGem.method_defined?(:compile_time)
end

chef_gem 'rest-client' do
  version node['s3_file']['rest-client']['version']
  action :install
  compile_time true if Chef::Resource::ChefGem.method_defined?(:compile_time)
end
