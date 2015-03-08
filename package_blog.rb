require_relative 'tumblr'

blog_href = ARGV.shift
puts "finding posts: #{blog_href}"

Tumblr::Blog.find_posts(blog_href)
.map do |post_details|
  puts "detailing: #{post_details}"
  Tumblr::Post.detail(post_details[:href])
end
.flat_map do |full_post_details|
  puts "finding images: #{full_post_details}"
  Tumblr::Post.find_images(full_post_details).to_a
end
.map do |image_details|
  puts "downloading: #{image_details}"
  image_details.merge({
    data: Tumblr::Image.download(image_details[:href])
  })
end
.map do |image_details_with_data|
  file_path = "/tmp/d/#{Base64.urlsafe_encode64(image_details_with_data[:href])}"
  puts "writing [#{image_details_with_data[:data].length}\: #{file_path}"
  File.write(file_path, image_details_with_data[:data])
end
