require File.dirname(__FILE__) + '/../spec_helper'

describe FlickrTags do
  dataset :users_and_pages, :file_not_found, :snippets
  
  describe "<r:flickr:slideshow>" do
    it "should require the username attribute" do
      message = "slideshow tag requires a Flickr NSID in the `user' attribute"
      page(:home).should render("<r:flickr:slideshow />").with_error(message)
    end
    
    it "should require set or tags attributes" do
      message = "slideshow tag must have a `set' or `tags' attribute"
      page(:home).should render("<r:flickr:slideshow user='foo' />").with_error(message)
    end
    
    it "should render an iframe for tags" do
      expected = %Q{<iframe align="center" src="http://www.flickr.com/slideShow/index.gne?user_id=user&tags=foo,bar" frameBorder="0" width="500" scrolling="no" height="500"></iframe>\n}
      page(:home).should render("<r:flickr:slideshow user='user' tags='foo,bar' />").as(expected)
    end
    
    it "should render an iframe for a set" do
      expected = %Q{<iframe align="center" src="http://www.flickr.com/slideShow/index.gne?user_id=user&set_id=123456" frameBorder="0" width="500" scrolling="no" height="500"></iframe>\n}
      page(:home).should render("<r:flickr:slideshow user='user' set='123456' />").as(expected)
    end
    
  end
  
  describe "<r:flickr:photos>" do    
    it "should retrieve photos from a user" do
      Flickr.stub_chain(:new, :photos, :search).and_return(flickr_photos_found)
      
      page(:home).should render("<r:flickr:photos user='44965307@N07'><r:photo:title /></r:flickr:photos>").as('Photo 1Photo 2')
    end
    
    it "should retrieve photos with tags from a user" do
      Flickr.stub_chain(:new, :photos, :search).and_return(flickr_photos_found)
      
      page(:home).should render("<r:flickr:photos user='44965307@N07' tags='chapel'><r:photo:title /></r:flickr:photos>").as('Photo 1Photo 2')
    end
    
    it "should retrieve photos with tags from all users" do
      Flickr.stub_chain(:new, :photos, :search).and_return(flickr_photos_found)
      
      page(:home).should render("<r:flickr:photos tags='portfolio'><r:photo:title /></r:flickr:photos>").as('Photo 1Photo 2')
    end
    
    end
    
  end
  
  private
    def flickr_photos_found
      photo1 = stub('photo 1')
      photo1.stub!(:title).and_return("Photo 1")
      photo2 = stub('photo 2')
      photo2.stub!(:title).and_return("Photo 2")
      [photo1, photo2]
    end
    
    def page(symbol = nil)
      if symbol.nil?
        @page ||= pages(:assorted)
      else
        @page = pages(symbol)
      end
    end
end

