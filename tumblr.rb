require 'uri'
require 'feedjira'
require 'httparty'
require 'persistent_httparty'

module Tumblr
  class Blog
    include HTTParty
    persistent_connection_adapter

    def find_posts blog_href
      Enumerator.new do |yielder|
        last_page = nil
        page_urls(blog_href).each do |page_number, page_url|
          puts "page: #{page_url}"
          page_data = self.class.get(page_url).body
          feed = Feedjira::Feed.parse(page_data)[urls.first]
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
    include HTTParty
    persistent_connection_adapter

    def detail post_href
      begin
        response = self.class.get("#{post_href}/xml",
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
    include HTTParty
    persistent_connection_adapter

    def download image_href
      begin
        response = self.class.get(image_href)
      rescue SocketError, Net::ReadTimeout
        retry
      end
      response.parsed_response
    end
  end
end
