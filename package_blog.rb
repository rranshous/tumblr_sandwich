require_relative 'tumblr'
require_relative 'memoize'
require_relative 'tar'
require 'pry'

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

blog_href = ARGV.shift
STDERR.puts "finding posts: #{blog_href}"

blog_client = Tumblr::Blog.new
post_client = Tumblr::Post.new
post_client.memoize :detail, './cache/post.cache'
post_client.memoize :find_images, './cache/post.cache'
image_client = Tumblr::Image.new
image_client.memoize :download, './cache/image.cache'

outputter = TarStream.new STDOUT

blog_client.find_posts(blog_href)
.lazy.map do |post_details|
  STDERR.puts "detailing: POST:#{post_details[:href]}"
  post_client.detail(post_details[:href])
end
.lazy.map do |full_post_details|
  STDERR.puts "finding images: POST:#{full_post_details[:href]}"
  post_client.find_images(full_post_details)
end
.lazy.flatten.map do |image_details|
  STDERR.puts "downloading: IMAGE:#{image_details[:href]} :: #{image_details[:post][:href]}"
  image_details.merge({
    data: image_client.download(image_details[:href])
  })
end
.map do |image_details_with_data|
  file_path = "#{Base64.urlsafe_encode64(image_details_with_data[:href])}"
  STDERR.puts "writing [#{image_details_with_data[:data].length}\: #{file_path}"
  outputter.add image_details_with_data[:data], file_path
end.to_a

