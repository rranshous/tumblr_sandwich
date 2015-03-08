require 'uri'
require 'feedjira'
require 'httparty'

module Tumblr
  class Blog
    def self.find_posts blog_href
      # TODO: dont skip page 1
      Enumerator.new do |yielder|
        last_page = nil
        (1..2).each do |page_number|
          urls = [self.url_join(blog_href,'/page/',"/#{page_number}/",'rss').to_s]
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
    def self.url_join *args
      args.map { |arg| arg.gsub(%r{^/*(.*?)/*$}, '\1') }.join("/")
    end
  end
  class Post
    def self.detail post_href
      begin
        response = HTTParty.get("#{post_href}/xml",
                                headers: {'Accept'=>'application/xml'})
      rescue SocketError => _
        retry
      end
      post_data = response.parsed_response
      unless post_data.is_a? Hash
        return nil
      end
      return { href: post_href }.merge post_data
    end
    def self.find_images post_data
      post_href = post_data[:href]
      Enumerator.new do |yielder|
        post_type = post_data["tumblr"]["posts"]["post"]["type"]
        if post_type != "photo"
          return []
        end
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
  class Image
    def self.download image_href
      begin
        response = HTTParty.get(image_href)
      rescue SocketError => _
        retry
      end
      response.parsed_response
    end
  end
end
