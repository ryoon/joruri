# encoding: utf-8
class Article::Public::Node::AreasController < Cms::Controller::Public::Base
  include Article::Controller::Feed
  
  def pre_dispatch
    return http_error(404) unless @content = Core.current_node.content
    
    @limit = 10
    
    if params[:name]
      item = Article::Area.new.public
      item.and :content_id, @content.id
      item.and :name, params[:name]
      return http_error(404) unless @item = item.find(:first)
      Page.current_item = @item
      Page.title        = @item.title
    end
  end
  
  def index
    @items = Article::Area.root_items(:content_id => @content.id, :state => 'public')
  end

  def show
    return http_error(404) unless params[:file] =~ /^(index|more)$/
    @more  = params[:file] == 'more'
    @limit = 50 if @more
    
    doc = Article::Doc.new.public
    doc.agent_filter(request.mobile)
    doc.and :content_id, @content.id
    request.mobile? ? doc.visible_in_list : doc.visible_in_recent
    doc.area_is @item
    doc.page params[:page], @limit
    @docs = doc.find(:all, :order => 'published_at DESC')
    return true if render_feed(@docs)

    if @item.level_no == 1
      show_group
      return render(:action => :show_group)
    elsif @item.level_no > 1
      show_detail
      return render(:action => :show_detail)
    end
    return http_error(404)
  end

  def show_group
    @items = @item.public_children

    @item_docs = Proc.new do |city|
      doc = Article::Doc.new.public
      doc.agent_filter(request.mobile)
      doc.and :content_id, @content.id
      doc.visible_in_list
      doc.area_is city
      doc.page 1, @limit
      @docs = doc.find(:all, :order => 'published_at DESC')
    end
  end

  def show_detail
    @items = Article::Attribute.new.public.find(:all, :order => :sort_no)

    @item_docs = Proc.new do |attr|
      doc = Article::Doc.new.public
      doc.agent_filter(request.mobile)
      doc.and :content_id, @content.id
      doc.visible_in_list
      doc.area_is @item
      doc.attribute_is attr
      doc.page 1, @limit
      @docs = doc.find(:all, :order => 'published_at DESC')
    end
  end
  
  def show_attr
    attr = Article::Attribute.new.public
    attr.and :name, params[:attr]
    return http_error(404) unless @attr = attr.find(:first, :order => :sort_no)
    
    doc = Article::Doc.new.public
    doc.agent_filter(request.mobile)
    doc.and :content_id, @content.id
    doc.visible_in_list
    doc.area_is @item
    doc.attribute_is @attr
    doc.page params[:page], @limit
    @docs = doc.find(:all, :order => 'published_at DESC')
  end
end
