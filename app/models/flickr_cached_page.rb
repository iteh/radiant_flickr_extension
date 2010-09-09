class FlickrCachedPage < Page
  include FlickrPageExtensions

  def cache?
    false
  end

end

