case node['platform_family']
when 'rhel', 'centos', 'amazon'
  package 'gcc' do
    action :nothing
  end.run_action(:install)
  package 'gcc-c++' do
    action :nothing
  end.run_action(:install)
when 'debian'
  apt_update 'update' do
    action :nothing
  end.run_action(:periodic)
  package 'g++' do
    action :nothing
  end.run_action(:install)
  package 'make' do
    action :nothing
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
