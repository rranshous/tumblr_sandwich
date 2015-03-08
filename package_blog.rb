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
  STDERR.puts msg if ARGV.to_a.include? '--debug'
end

blog_href = ARGV.shift
use_cache = ARGV.to_a.include?('--use-cache')
log "finding posts: #{blog_href}"

blog_client = Tumblr::Blog.new
post_client = Tumblr::Post.new
image_client = Tumblr::Image.new

if use_cache
  post_client.memoize :detail, './cache/post.cache'
  post_client.memoize :find_images, './cache/post.cache'
  image_client.memoize :download, './cache/image.cache'
end

outputter = TarStream.new STDOUT

blog_client.find_posts(blog_href)
.lazy.map do |post_details|
  log "detailing: POST:#{post_details[:href]}"
  post_client.detail(post_details[:href])
    .merge({ page_number: post_details[:page_number] })
end
.lazy.map do |full_post_details|
  log "finding images: POST:#{full_post_details[:href]}"
  post_client.find_images(full_post_details)
end
.lazy.flatten.map do |image_details|
  log "downloading: IMAGE:#{image_details[:href]} :: #{image_details[:post][:href]}"
  image_details.merge({
    data: image_client.download(image_details[:href])
  })
end
.map do |image_details_with_data|
  file_path = "#{Base64.urlsafe_encode64(image_details_with_data[:href])}"
  log "writing [#{image_details_with_data[:data].length}\: #{file_path}"
  outputter.add image_details_with_data[:data], file_path
  outputter.flush
end.to_a

