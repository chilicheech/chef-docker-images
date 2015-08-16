
packagecloud_repo 'chef/stable' do
  type 'rpm'
end

package 'chef' do
  version '12.4.1-1.el6'
  action :install
end
