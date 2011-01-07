module FlickrTags

  #monkey patch flickr for primary
  class Flickr::Photosets::Photoset
    attr_accessor :id, :num_photos, :title, :description, :primary
  end

  class Flickr::Photosets < Flickr::Base
    def create_attributes(photoset)
      {
              :id => photoset[:id],
              :num_photos => photoset[:photos],
              :title => photoset.title.to_s,
              :description => photoset.description.to_s,
              :primary => photoset[:primary]
      }
    end

  end
  class Flickr::Photos
    def protected_find_id(id)
      self.send(:find_by_id,id)
    end
  end

  class Flickr::Photos::Photo
     def to_json
      {
      :is_public => "#{self.is_public}",
      :id => "#{self.id}", :owner => "#{self.owner}",
      :secret => "#{self.secret}", :server =>"#{self.server}", :farm => "#{self.farm}",
      :title => "#{self.title}",  :is_friend => "#{self.is_friend}", :is_family => "#{self.is_family}"
      }.to_json
     end
  end

  include Radiant::Taggable

  class TagError < StandardError;
  end

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

    if attr[:set] && attr[:tags]
      raise TagError.new("slideshow tag must have either a `set' or `tags' attribute, not both")
    elsif attr[:set]
      get_flickr_iframe user, 'set_id', attr[:set].strip
    elsif attr[:tags]
      get_flickr_iframe user, 'tags', attr[:tags].strip
    else
      raise TagError.new("slideshow tag must have a `set' or `tags' attribute")
    end
  end

  desc %{
    Gives access to photos by a user, with a tag, or in a set.
    if you set the page type to FlickrPage and set the flickr_user in the config yaml or in the settings
    currently with the key flickr.page_id.{Page_ID}.user and ommit user, tags, and the set attribute it will
    default to the set with the slug of the set title in parameterized form

    *Usage:*
    
    <pre><code><r:flickr:photos [user="10622160@N00"] [tags="one, two"] [set="72157622808879505"]>...</r:flickr:photos></code></pre>
  }

  tag 'flickr:photos' do |tag|

    attr = tag.attr.symbolize_keys

    options = {}

    [:per_page, :page].each do |symbol|
      if number = attr[symbol]
        if number =~ /^\d{1,4}$/
          options[symbol] = number.to_i
        else
          raise TagError.new("`#{symbol}' attribute of `photos' tag must be a positive number between 1 and 4 digits")
        end
      end
    end

    if :flickr_set == @flickr_page_type && !(attr[:set] || attr[:user] || attr[:tags])
      tag.locals.photos = get_cached_set(@flickr_current_set.id)
    elsif attr[:set]
      tag.locals.photos = get_cached_set(attr[:set], options)
    elsif attr[:user] || attr[:tags]
      tag.locals.photos = Rails.cache.fetch("flickr_#{attr[:user]}_#{attr[:tags]}", :expires_in => flickr_expires_in) do
        begin
          tag.locals.photos = flickr.photos.search(:user_id => attr[:user], 'per_page' => options[:per_page], 'page' => options[:page], 'tags' => attr[:tags])
        rescue Exception => e
          logger.error "Unable to fetch flickr photos: #{e} #{e.inspect}"
        end
      end
    else
      raise TagError.new("The `photos' tag requires at least one `user' `tags' or `set' attribute.") if attr[:user].blank?
    end

    result = ''

    tag.locals.photos.each do |photo|
      tag.locals.photo = photo
      result << tag.expand
    end

    result

  end

  desc %{
    The title of the photoset
  }
  tag 'flickr:photos:set_title' do |tag|
    tag.locals.set.title
  end

  desc %{
    The description of the photoset
  }
  tag 'flickr:photos:set_description' do |tag|
    tag.locals.set.description
  end

  desc %{
    The Context of the image set through <r:flickr:photos/>
  }
  tag 'flickr:photos:photo' do |tag|
    tag.expand
  end

  desc %{
    The src attribute of the image

      square - square 75x75
      thumbnail - 100 on longest side
      small - 240 on longest side
      medium - 500 on longest side
      large - 1024 on longest side (only exists for very large original images)
      original - original image, either a jpg, gif or png, depending on source format

    *Usage:*

    <pre><code><r:flickr:photo:src [size="Medium"]/></code></pre>
  }
  tag 'flickr:photos:photo:src' do |tag|
    tag.attr['size'] ||= 'Medium'
    tag.locals.photo.image_url(tag.attr['size'].downcase.to_sym)
  end

  desc %{
    The url of the image

    *Usage:*

    <pre><code><r:flickr:photos:photo:url_photopage/></code></pre>
  }
  tag 'flickr:photos:photo:url_photopage' do |tag|
    tag.locals.photo.url_photopage
  end

  desc %{
    The description attribute of the image

    *Usage:*

    <pre><code><r:flickr:photos:photo:description/></code></pre>
  }
  tag 'flickr:photos:photo:description' do |tag|
    tag.locals.photo.description
  end

  desc %{
    The title attribute of the image

    *Usage:*

    <pre><code><r:flickr:photos:photo:title/></code></pre>
  }
  tag 'flickr:photos:photo:title' do |tag|
    tag.locals.photo.title
  end

  desc %{
    Gives access to sets of a user

    *Usage:*

    <pre><code><r:flickr:sets user="10622160@N00">...</r:flickr:sets></code></pre>
  }

  tag 'flickr:sets' do |tag|

    attr = tag.attr.symbolize_keys
    raise TagError.new("The `sets' tag requires at least the `user' attribute.") if attr[:user].blank?

    tag.locals.sets = get_cached_sets(attr[:user])

    result = ''

    tag.locals.sets.each do |set|
      tag.locals.set = set
      result << tag.expand
    end

    result

  end

  desc %{
    Display Info about a flickr set

    you can ommit the set id if you are on a FlickrPage displaying a set
    *Usage:*

    <pre><code><r:flickr:set [set="the-set-id"]/></code></pre>
  }
  tag 'flickr:set' do |tag|
    attr = tag.attr.symbolize_keys
    if (@flickr_page_type == :flickr_set && @flickr_current_set.nil?) then
      raise TagError.new("you are on a set page, but we could not find the set of the page")
    elsif @flickr_page_type != :flickr_set && attr[:set].blank? then
      raise TagError.new("if you are not in a set context you must provide a set attribute")
    end

    if tag.locals.set = attr[:set].blank? ? @flickr_current_set : get_cached_set(attr[:set])
      tag.expand
    end
  end

  [:title, :description, :num_photos, :id].each do |method|
    desc %{
    The #{method.to_s} attribute of the set

    *Usage:*

    <pre><code><r:flickr:set:#{method.to_s}/></code></pre>
  }
    tag "flickr:set:#{method.to_s}" do |tag|
      tag.locals.set.send(method)
    end
  end



  desc %{
    The Context of the set through <r:flickr:sets/>
  }
  tag 'flickr:sets:set' do |tag|
    tag.expand
  end


  desc %{
    The title attribute of the set

    *Usage:*

    <pre><code><r:flickr:sets:set:title/></code></pre>
  }
  tag 'flickr:sets:set:title' do |tag|
    tag.locals.set.title
  end

  desc %{
    The local url for the gallery of the set

    *Usage:*

    <pre><code><r:flickr:sets:set:url path="some/custom/path"/></code></pre>
  }
  tag 'flickr:sets:set:url' do |tag|
    attr = tag.attr.symbolize_keys
    path = attr[:path] || tag.globals.page.url
    File.join(path, tag.locals.set.title.parameterize)
  end

  desc %{
    The description attribute of the set

    *Usage:*

    <pre><code><r:flickr:sets:set:description/></code></pre>
  }
  tag 'flickr:sets:set:description' do |tag|
    tag.locals.set.description
  end

  desc %{
    The Context of the primary image through <r:flickr:sets:set:primary/>
  }
  tag 'flickr:sets:set:primary' do |tag|
    tag.locals.photo = get_cached_photo(tag.locals.set.primary)
    # tag.locals.photo = flickr.photos.find_by_id(tag.locals.set.primary)
    tag.expand unless tag.locals.photo.nil?
  end

  desc %{
    The img_src attribute of the primary image of the set
    set size to:

      square - square 75x75
      thumbnail - 100 on longest side
      small - 240 on longest side
      medium - 500 on longest side
      large - 1024 on longest side (only exists for very large original images)
      original - original image, either a jpg, gif or png, depending on source format

    *Usage:*

    <pre><code><r:flickr:sets:set:img_src [size='']/></code></pre>
  }
  tag 'flickr:sets:set:primary:img_src' do |tag|
    tag.attr['size'] ||= 'Medium'
    tag.locals.photo.image_url(tag.attr['size'].downcase.to_sym)
  end


  private

  def get_cached_sets(user)
    Rails.cache.fetch("flickr_#{user}_set_list",  :expires_in => flickr_expires_in) do
      begin
        flickr.photosets.get_list :user_id => user
      rescue Exception => e
        logger.error "Unable to fetch flickr sets: #{e} #{e.inspect}"
      end
    end
  end

  def get_cached_set(set_id, options={:per_page => 500, :page => 1})
    Rails.cache.fetch("flickr_set_#{set_id}_#{options[:per_page]}_#{options[:page]}", :expires_in => flickr_expires_in) do
      begin
        Flickr::Photosets::Photoset.new(flickr, {:id => set_id}).get_photos('per_page' => options[:per_page], 'page' => options[:page])
      rescue Exception => e
        logger.error "Unable to fetch flickr set: #{e} #{e.inspect}"
      end
    end
  end

  def get_cached_photo(photo_id)
    resp = JSON.parse(Rails.cache.fetch("flickr_photo_info_#{photo_id}", :expires_in => flickr_expires_in) do
      begin
        result = flickr.photos.protected_find_id(photo_id).to_json
      rescue Exception => e
        logger.error "Unable to fetch flickr photo info: #{e} #{e.inspect}"
        result = {}
      end
      result
    end)
    resp
    Flickr::Photos::Photo.new(flickr,resp)
  end

  def flickr
    @flickr ||= Flickr.new(flickr_config)
  end

  def flickr_config
    @flickr_config ||= YAML.load_file("#{RAILS_ROOT}/config/flickr.yml")
  end

  def current_page_flickr_user
    page_setting_flickr_user = Radiant::Config["flickr.page_id.#{self.id}.user"]
    config_setting_flickr_user = flickr_config["flickr_user"]
    (page_setting_flickr_user && !page_setting_flickr_user.empty?) ? page_setting_flickr_user : config_setting_flickr_user
  end

  def flickr_expires_in
    return @flickr_expires_in if @flickr_expires_in
    config_expires_in = Radiant::Config["flickr.expires_in"] ? eval(Radiant::Config["flickr.expires_in"]) : nil
    @flickr_expires_in = config_expires_in || 5.minutes  
  end

end


