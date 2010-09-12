class FlickrPage < Page

  attr_accessor(:flickr_user)

  include FlickrPageExtensions
  
  def cache?
    true
  end
  
end

