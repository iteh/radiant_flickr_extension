module FlickrPageExtensions

  include Radiant::Taggable

  class FlickrTagError < StandardError; end

  desc %{
    Usage:
    <pre><code><r:flickr:if_index>...</r:flickr:if_index></code></pre> }
  tag "flickr:if_index" do |tag|
    unless @item && !@item.empty?
      tag.expand
    end
  end

  desc %{
    Usage:
    <pre><code><r:flickr:unless_index>...</r:flickr:unless_index></code></pre> }
  tag "flickr:unless_index" do |tag|
    if @item && !@item.empty?
      tag.expand
    end
  end

  desc %{
    Usage:
    <pre><code><r:flickr:gallery_link /></code></pre>
    Provides link for current gallery options are rendered
    inline as key:value pairs i.e. class='value' id='value', etc.}
  tag "flickr:link" do |tag|
    gallery = find_gallery(tag)
    options = tag.attr.dup
    anchor = options['anchor'] ? "##{options.delete('anchor')}" : ''
    attributes = options.inject('') { |s, (k, v)| s << %{#{k.downcase}="#{v}" } }.strip
    attributes = " #{attributes}" unless attributes.empty?
    text = tag.double? ? tag.expand : tag.render('name')
    gallery_url = File.join(tag.render('url'), gallery.url(self.base_gallery_id))
    %{<a href="#{gallery_url}#{anchor}"#{attributes}>#{text}</a>}
  end

  desc %{
    Usage:
    <pre><code><r:flickr:gallery_url /></code></pre>
    Provides url for current gallery }
  tag "flickr:gallery_url" do |tag|
    gallery = find_gallery(tag)
    File.join(tag.render('url'), gallery.url(self.base_gallery_id))
  end

  desc %{
    Usage:
    <pre><code><r:flickr:if_gallery>....</r:flickr:if_gallery></code></pre>
    Check if we have a gallery to display
  }
  tag 'flickr:if_gallery' do |tag|
    tag.expand if @item && @action =~ /set|tags/
  end

  desc %{
    Usage:
    <pre><code><r:flickr:unless_gallery>....</r:flickr:unless_gallery></code></pre>
    Check if we don't have a gallery to display
  }
  tag 'flickr:unless_gallery' do |tag|
    tag.expand unless @item && @action =~ /set|tags/
  end

  def find_by_url(url, live = true, clean = false)

    url = clean_url(url)
    if url =~ /^#{self.url}(.*)/
      item, action = $1, "index"
      if item =~ /^([\w|-]+)\/?(set|tags)?\/?$/
        item, action = $1, $2||"set"
        case action
          when "set" then setup_set_page(item)
          when "index" then setup_index_page
        end
      end
      @item,@action = item, action
      self
    else
      super
    end
  end

  def setup_set_page(item)
    @flickr_page_type = :flickr_set
    @flickr_usr_sets = get_cached_sets(current_page_flickr_user)
    @flickr_current_set = @flickr_usr_sets.detect { |set| set.title.parameterize == item }
  end

  def setup_index_page
    @flickr_page_type = :flickr_index
    @flickr_usr_sets = get_cached_sets(current_page_flickr_user)
  end

  def title
    :flickr_set == @flickr_page_type ? @flickr_current_set.title : super
  end

  def description
    :flickr_set == @flickr_page_type ? @flickr_current_set.description : super
  end

end