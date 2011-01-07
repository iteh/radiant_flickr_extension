require 'flickr_fu'
#require 'flickraw'

class FlickrExtension < Radiant::Extension
  version "0.2"
  description "Provides tags for embedding Flickr slideshows and photos"
  url "http://github.com/iteh/flickr"
  
  def activate 
#    Radiant::Config["flickr.cache_time"] = "86400" if Radiant::Config["flickr.cache_time"].nil?
    Page.send :include, FlickrTags
    FlickrPage
  end
end