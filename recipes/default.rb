####
docker_service 'default' do
  action [:create, :start]
end

docker_image 'fedora' do
  action :pull_if_missing
end

%w( 12.0.0 12.0.1 12.0.3 12.1.0 12.1.1 12.1.2 12.2.1 12.3.0 12.4.0 12.4.1 ).each do |version|
  docker_container "chef-#{version}" do
    repo 'fedora'
    tag 'latest'
    command "bash -c 'curl -L https://www.chef.io/chef/install.sh | bash -s -- -v #{version}'"
    detach false
  end

  directory "/opt/chefbuilder-#{version}" do
    owner 'root'
    group 'root'
    mode '0755'
    recursive true
    action :create
  end

  execute "copy chef-#{version}" do
    command "docker cp chef-#{version}:/opt /opt/chefbuilder-#{version}"
    creates "/opt/chefbuilder-#{version}/opt"
  end

  file "/opt/chefbuilder-#{version}/Dockerfile" do
    content <<-EOF
    FROM scratch
    ADD opt /opt
    EOF
    owner 'root'
    group 'root'
    mode '0644'
    action :create
  end

  docker_image "someara/chef #{version}" do
    repo 'someara/chef'
    tag version
    source "/opt/chefbuilder-#{version}"
    action :build_if_missing
  end
end
