class FlickrPage < Page
  
  include FlickrPageExtensions
  
  def cache?
    false
  end
  
end

