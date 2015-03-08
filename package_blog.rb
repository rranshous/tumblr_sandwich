require_relative 'tumblr'

module Enumerable
  def lazy_flatten
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
    end
  end
end

blog_href = ARGV.shift
puts "finding posts: #{blog_href}"

Tumblr::Blog.find_posts(blog_href)
.lazy.map do |post_details|
  puts "detailing: POST:#{post_details[:href]}"
  Tumblr::Post.detail(post_details[:href])
end
.lazy.map do |full_post_details|
  puts "finding images: POST:#{full_post_details[:href]}"
  Tumblr::Post.find_images(full_post_details)
end
.lazy_flatten.map do |image_details|
  puts "downloading: IMAGE:#{image_details[:href]} :: #{image_details[:post][:href]}"
  image_details.merge({
    data: Tumblr::Image.download(image_details[:href])
  })
end
.lazy.map do |image_details_with_data|
  file_path = "/tmp/d/#{Base64.urlsafe_encode64(image_details_with_data[:href])}"
  puts "writing [#{image_details_with_data[:data].length}\: #{file_path}"
  File.write(file_path, image_details_with_data[:data])
end





