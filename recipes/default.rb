####
docker_image 'fedora' do
  action :pull_if_missing
end

# variables
account = node['chef-docker-images']['account']

package 'curl' do
  action :install
end

package 'rpm2cpio' do
  action :install
end

# resource generation loop
node['chef-docker-images']['versions'].each do |version|

  chef_url = `wget -qO- "http://omnitruck.chef.io/stable/chef/metadata?p=el&pv=5&m=x86_64&v=#{version}" 2>&1 | grep ^url | awk '{ print $2 }'`.chomp
  chef_sha256 = `wget -qO- "http://omnitruck.chef.io/stable/chef/metadata?p=el&pv=5&m=x86_64&v=#{version}" 2>&1 | grep ^sha256 | awk '{ print $2 }'`.chomp

  # require 'pry' ; binding.pry
  
  remote_file "/root/chef-#{version}.el5.rpm" do
    source chef_url
    checksum chef_sha256
  end
      
  directory "/opt/chefbuilder-#{version}" do
    owner 'root'
    group 'root'
    mode '0755'
    recursive true
    action :create
  end

  execute "rpm2cpio /root/chef-#{version}.el5.rpm | cpio -idmv" do
    cwd "/opt/chefbuilder-#{version}"
    creates "/opt/chefbuilder-#{version}/opt"
    action :run
  end 

  file "/opt/chefbuilder-#{version}/Dockerfile" do
    content <<-EOF
    FROM scratch
    ADD opt /opt
    VOLUME [ '/opt/chef' ]
    EOF
    owner 'root'
    group 'root'
    mode '0644'
    action :create
  end

  docker_image "#{account}/chef #{version}" do
    repo "#{account}/chef"
    tag version
    source "/opt/chefbuilder-#{version}"
    action :build_if_missing
  end
end
