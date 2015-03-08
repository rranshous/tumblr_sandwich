require 'httparty'
require 'uri'

DATA_DIR=ENV['OUTDIR'] || File.absolute_path('./data')

def run(cmd, opt=nil)
  puts " --> running: #{cmd}"
  unless system(cmd)
    raise "Error running: #{cmd}" unless opt==:FAILOK
  end
end

def docker_run(name, image, options, command, *args)
  puts " -> removing old container"
  run "docker stop #{name}", :FAILOK
  run "docker rm #{name}", :FAILOK
  run "docker run --restart=always -d " + \
      "--name \"#{name}\" " + \
      "#{options} #{image} #{command} #{args.join(' ')}"
end

def start_scraper blog_href
  name = "scrape-#{URI(blog_href).host}"
  docker_run(name,
             'rranshous/tumblr_sandwich',
             "-v #{DATA_DIR}:/data",
             blog_href, '--use-cache')
end

url = 'https://gist.githubusercontent.com/rranshous/30056e2109f43e74d79f/raw/'
blog_hrefs = HTTParty.get(url).parsed_response
  .split("\n").map(&:chomp)
  .reject{|i|i.start_with?('#')}
  .reject{|i|i.chomp==''}
blog_hrefs.each do |blog_href|
  start_scraper blog_href
end
