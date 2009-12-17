module FlickrTags
  include Radiant::Taggable
  
  class TagError < StandardError; end
  
  def get_flickr_iframe(user, param_name, param_val)
<<EOS
<iframe align="center" src="http://www.flickr.com/slideShow/index.gne?user_id=#{user}&#{param_name}=#{param_val}" frameBorder="0" width="500" scrolling="no" height="500"></iframe>
EOS
  end

  
  tag "flickr" do |tag|
    tag.expand
  end
  
  desc %{
    Embeds a slideshow into a page using an iframe. Photographs for the slideshow can be selected using a Flickr photoset ID or a comma-separated list of Flickr tags.
    
    *Usage:*
    
    <pre><code><r:flickr:slideshow user="10622160@N00" tags="portfolio"/>
    <r:flickr:slideshow user="10622160@N00" set="548374"/></code></pre>
  }
  tag "flickr:slideshow" do |tag|
    attr = tag.attr.symbolize_keys
    
    if (attr[:user])
      user = attr[:user].strip
    else
      raise TagError.new("slideshow tag requires a Flickr NSID in the `user' attribute")
    end
    
    if attr[:set]
      get_flickr_iframe user, 'set_id', attr[:set].strip
    elsif attr[:tags]
      get_flickr_iframe user, 'tags', attr[:tags].strip
    else
      raise TagError.new("slideshow tag must have a `set' or `tags' attribute")
    end 
  end
  
  desc %{
    Gives access to photos by a user, with a tag, or in a set.

    *Usage:*
    
    <pre><code><r:flickr:photos [user="10622160@N00"] [tags="one, two"] [set="72157622808879505"]>...</r:flickr:photos></code></pre>
  }
  tag 'flickr:photos' do |tag|
    
    cachekey = "flickrfotos-" + Date.today.to_s
    Rails.cache.fetch(cachekey) do
      logger.info "Flickr cache miss"

      attr = tag.attr.symbolize_keys

      options = {}

      [:limit, :offset].each do |symbol|
        if number = attr[symbol]
          if number =~ /^\d{1,4}$/
            options[symbol] = number.to_i
          else
            raise TagError.new("`#{symbol}' attribute of `photos' tag must be a positive number between 1 and 4 digits")
          end
        end
      end

      flickr = Flickr.new "#{RAILS_ROOT}/config/flickr.yml"
      tag.locals.photos = flickr.photos.search(:user_id => tag.attr['user'], 'per_page' => options[:limit], 'page' => options[:offset], 'tags' => tag.attr['tags'])

      result = ''

      tag.locals.photos.each do |photo|
        tag.locals.photo = photo
        result << tag.expand
      end

      result
    end
  end

  tag 'flickr:photos:photo' do |tag|
    tag.expand
  end

  tag 'flickr:photos:photo:src' do |tag|
    tag.attr['size'] ||= 'Medium'
    tag.locals.photo.sizes.find{|p| p.label.downcase == tag.attr['size'].downcase}.source 
  end

  tag 'flickr:photos:photo:url' do |tag|
    tag.locals.photo.url_photopage
  end

  tag 'flickr:photos:photo:description' do |tag|
    tag.locals.photo.description
  end

  tag 'flickr:photos:photo:title' do |tag|
    tag.locals.photo.title
  end   
end
