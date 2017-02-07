#!/usr/bin/env ruby
require 'httparty'
require 'uri'

DATA_DIR=ENV['OUTDIR'] || File.absolute_path('./data')
HREFS_URL=ENV['HREFS_URL']
MAX_PARALLEL = (ENV['MAX_PARALLEL'] || 10).to_i

$failok = ARGV.include? '--failok'
$is_full = ARGV.include? '--full'
$serial = ARGV.include? '--serial'
$limit_parallel = ARGV.include? '--limit-parallel'


puts "starting"
puts
puts "failok: #{$failok}"
puts "full: #{$is_full}"
puts "serial: #{$serial}"
puts "limit-parallel: #{$limit_parallel}"
puts "MAX_PARALLEL: #{MAX_PARALLEL}" if $limit_parallel
puts

def run(cmd, opt=nil)
  puts " --> running: #{cmd}"
  unless system(cmd)
    raise "Error running: #{cmd}" unless opt==:FAILOK || $failok
  end
end

def count_scrapers
  result = `docker ps | grep scrape- | wc -l`
  puts "count result: #{result}"
  return result.to_i
end

def docker_run(name, image, options, command, *args)
  puts " -> removing old container"
#  run "docker stop #{name}", :FAILOK
  run "docker rm #{name}", :FAILOK
  cmd = "docker run "
  cmd += "-d " if !$serial
  cmd += "-e http_proxy=#{ENV['http_proxy']} " + \
         "--name \"#{name}\" " + \
         "#{options} #{image} #{command} #{args.join(' ')}"
  run cmd
end

def start_scraper blog_href
  puts "starting: #{blog_href}"
  host = URI(blog_href).host || blog_href
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
blog_hrefs.reverse.each do |blog_href|
  while $limit_parallel && count_scrapers >= MAX_PARALLEL
    puts 'too many scrapers, sleeping'
    sleep 5
  end
  start_scraper blog_href
  puts
end
