#!/usr/bin/env ruby
require 'httparty'
require 'uri'

DATA_DIR=ENV['OUTDIR'] || File.absolute_path('./data')
HREFS_URL=ENV['HREFS_URL']
$is_full = ARGV.include? '--full'

def run(cmd, opt=nil)
  puts " --> running: #{cmd}"
  unless system(cmd)
    raise "Error running: #{cmd}" unless opt==:FAILOK
  end
end

def docker_run(name, image, options, command, *args)
  puts " -> removing old container"
#  run "docker stop #{name}", :FAILOK
  run "docker rm #{name}", :FAILOK
  run "docker run --restart=on-failure -d " + \
      "-e http_proxy=#{ENV['http_proxy']} " + \
      "--name \"#{name}\" " + \
      "#{options} #{image} #{command} #{args.join(' ')}"
end

def start_scraper blog_href
  host = URI(blog_href).host
  name = "scrape-#{host}"
  args = [name,
          'rranshous/tumblr-sandwich:latest',
          "-v #{DATA_DIR}/#{host}:/data",
          blog_href]
  args << '--full' if $is_full
  docker_run(*args)
  puts "started: #{name}"
end

blog_hrefs = HTTParty.get(HREFS_URL).parsed_response
  .split("\n").map(&:chomp)
  .reject{|i|i.start_with?('#')}
  .reject{|i|i.chomp==''}
blog_hrefs.each do |blog_href|
  start_scraper blog_href
end
