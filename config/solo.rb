CHEF_ROOT = File.join(File.dirname(__FILE__), "..")

cookbook_path   File.join(CHEF_ROOT, "cookbooks")
file_store_path CHEF_ROOT
file_cache_path CHEF_ROOT