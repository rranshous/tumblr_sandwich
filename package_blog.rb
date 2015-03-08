require_relative 'tumblr'
require_relative 'memoize'
require_relative 'tar'

module Tumblr
  class Blog; include Memoize; end
  class Post; include Memoize; end
  class Image; include Memoize; end
end

module Enumerable
  def flatten
    Enumerator.new do |yielder|
      each do |element|
        if element.is_a? Hash
          yielder << element
        elsif element.is_a? Enumerable
          element.each do |e|
            yielder.yield(e)
          end
        else
          yielder.yield(element)
        end
      end
    end.lazy
  end
end

def log msg
  puts msg
end

OUTDIR = ENV['OUTDIR'] || './data'
CACHEDIR = ENV['CACHEDIR'] || './cache'
puts "outdir: #{OUTDIR}"
puts "cachdir: #{CACHEDIR}"
blog_href = ARGV.shift
use_cache = ARGV.to_a.include?('--use-cache')
log "finding posts: #{blog_href}"

blog_client = Tumblr::Blog.new
post_client = Tumblr::Post.new
image_client = Tumblr::Image.new

if use_cache
  post_client.memoize :detail, "#{CACHEDIR}/post.cache"
  post_client.memoize :find_images, "#{CACHEDIR}/post.cache"
  image_client.memoize :download, "#{CACHEDIR}/image.cache"
end

blog_client.find_posts(blog_href)
.lazy.map do |post_details|
  log "detailing: POST:#{post_details[:href]}"
  post_client.detail(post_details[:href])
    .merge({ page_number: post_details[:page_number] })
end
.map do |full_post_details|
  log "finding images: POST:#{full_post_details[:href]}"
  post_client.find_images(full_post_details).first
end
.flatten.reject(&:nil?).map do |image_details|
  file_path = "#{OUTDIR}/#{Base64.urlsafe_encode64(image_details[:href])}"
  if File.exists? file_path
    nil
  else
    log "downloading: IMAGE:#{image_details[:href]} " \
        ":: #{image_details[:post][:href]}"
    image_details.merge({
      data: image_client.download(image_details[:href])
    })
  end
end
.reject(&:nil?).map do |image_details_with_data|
  file_path = "#{OUTDIR}/#{Base64.urlsafe_encode64(image_details_with_data[:href])}"
  log "writing [#{image_details_with_data[:data].length}\: #{file_path}"
  File.write file_path, image_details_with_data[:data]
end.to_a

