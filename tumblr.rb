require 'uri'
require 'feedjira'
require 'httparty'

module Tumblr
  class Blog
    def find_posts blog_href
      Enumerator.new do |yielder|
        last_page = nil
        page_urls(blog_href).each do |page_number, page_url|
          puts "page: #{page_url}"
          urls = [page_url]
          feed = Feedjira::Feed.fetch_and_parse(urls)[urls.first]
          if feed.is_a?(Fixnum)
          else
            if feed.entries.length == 0
              break
            end
            feed.entries.each do |entry|
              post_data = {
                :href => entry.url,
                :page_number => page_number,
                :blog => { :href => feed.url },
              }
              yielder << post_data
            end
          end
          last_page = page_number
        end end
    end
    private
    def url_join *args
      args.map { |arg| arg.gsub(%r{^/*(.*?)/*$}, '\1') }.join("/")
    end
    def page_urls blog_href
      Enumerator.new do |yielder|
        yielder << [1, "#{blog_href}/rss"]
        (2..10000).each do |page_number|
          yielder << [page_number,
                      url_join(blog_href,'/page/',"/#{page_number}/",'rss').to_s]
        end
      end
    end
  end
  class Post
    def detail post_href
      begin
        response = HTTParty.get("#{post_href}/xml",
                                headers: {'Accept'=>'application/xml'})
      rescue SocketError, Net::ReadTimeout
        retry
      end
      post_data = response.parsed_response
      unless post_data.is_a? Hash
        return nil
      end
      return { href: post_href }.merge post_data
    end
    def find_images post_data
      post_href = post_data[:href]
      Enumerator.new do |yielder|
        post_type = post_data["tumblr"]["posts"]["post"]["type"]
        if post_type == "photo"
          image_versions = Hash[
            post_data["tumblr"]["posts"]["post"]["photo_url"]
            .map{|d| [d["max_width"].to_i, d["__content__"]] }
          ]
          image_versions.each do |width, url|
            image_data = {
              href: url,
              width: width,
              post: { href: post_href }
            }
            yielder << image_data
          end
        end
      end
    end
  end
  class Image
    def download image_href
      begin
        response = HTTParty.get(image_href)
      rescue SocketError, Net::ReadTimeout
        retry
      end
      response.parsed_response
    end
  end
end
