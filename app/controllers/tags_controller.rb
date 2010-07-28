# Controller for operations on tags in the database.
#
# Author::      Eli Fox-Epstein, efoxepstein@wesleyan.edu
# Author::      Dimitar Gochev, dimitar.gochev@trincoll.edu
# Copyright::   Humanitarian FOSS Project (http://www.hfoss.org), Copyright (C) 2009.
# License::     http://www.gnu.org/copyleft/lesser.html GNU Lesser General Public License (LGPL)

class TagsController < AuthorizedController
  skip_before_filter :require_login

  def index
    @tags = @instance.tags.paginate(:all, :page => params[:page], :per_page => 20).sort{|a,b|a.name<=>b.name}
#    return with_rejection unless @current_user.can? :list => @tags
    return with_rejection unless ((@current_user && (@current_user.can? :list => @tags)) || Admin.current)
  end

  def show
    @instance = Instance.find(Integer(params[:instance]))
    @tag = @instance.tags.find(params[:id], :include => [:groups, :updates])
#    return with_rejection unless @current_user.can? :show => @tag
    return with_rejection unless ((@current_user && (@current_user.can? :show => @tag)) || Admin.current)
  end

  def destroy
    @tag = Tag.find(params[:id])
#    return with_rejection unless @current_user.can? :destroy => @tag
    return with_rejection unless ((@current_user && (@current_user.can? :destroy => @tag)) || Admin.current)
    @tag.destroy
    flash[:notice] = t('notice.tag.destroyed')
    redirect_to :back
  end

  def create_bulk
    @instance = Instance.find(Integer(params[:id]))
    tags = params[:tags].split(',').collect {|t| t.strip}.select {|t| t.length > 0}
    tags.each do |tag_name|
      Tag.create(:name => tag_name, :instance => @instance)
    end
    redirect_to :back
  end
end

