require 'flickr_fu'
#require 'flickraw'

class FlickrExtension < Radiant::Extension
  version "0.2"
  description "Provides tags for embedding Flickr slideshows and photos"
  url "http://github.com/santry/flickr_tags"
  
  def activate
    Page.send :include, FlickrTags
    FlickrPage
    FlickrCachedPage
  end
end