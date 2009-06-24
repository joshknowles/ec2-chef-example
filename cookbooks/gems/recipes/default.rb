node[:gems].each do |gem|
  gem_package gem[:name] do
    version gem[:version]
    
    action :install
  end
end