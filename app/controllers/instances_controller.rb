# Controller for operations on instances in the database.
#
# Author::      Eli Fox-Epstein, efoxepstein@wesleyan.edu
# Author::      Dimitar Gochev, dimitar.gochev@trincoll.edu
# Copyright::   Humanitarian FOSS Project (http://www.hfoss.org), Copyright (C) 2009.
# License::     http://www.gnu.org/copyleft/lesser.html GNU Lesser General Public License (LGPL)

class InstancesController < AuthorizedController
  
  before_filter :setup_editable_permissions, :only => [:update, :edit, :create]
  skip_before_filter :require_login, :only => [:edit, :update, :new, :create, :destroy]
  layout 'home'


  def index
    @instances = Instance.all
    return with_rejection unless @current_user.can? :list => @instances
  end

  def show
    @incidents = @instance.incidents.find(:all,
                                          :include => [:updates],
                                          :order => 'created_at DESC',
                                          :conditions => ['created_at > ?', 2.months.ago.to_i])
    return with_rejection unless @current_user.can? :list => @incidents, :view => @instance
  end

  # Method for displaying the information needed on the 'Edit instance' page,
  # which lets the user edit the name of the instance and the permissions
  # associated with each role.
  # It passes the permissions to the view in a hash in which the
  # permissions are organized by their model.
  def edit
    @instance = Instance.find(Integer(params[:id]))
    return with_rejection unless ((@current_user && (@current_user.can? :update => @instance)) || Admin.current)
    @roles = @instance.roles
  end

  # Updates an existing instance object in the database specified by its :id
  # The data to be saved is provided in the :instance hash,
  # which is populated by the form on the 'edit' page
  # It also saves the updated permissions to the database based
  # on the :permissions hash
  def update
    @instance = Instance.find(Integer(params[:instance][:id]))
#   flash[:notice] = "instance is " + params[:instance][:long_name]
#    return with_rejection unless @current_user.can? :update => @instance
    return with_rejection unless ((@current_user && (@current_user.can? :update => @instance)) || Admin.current)
    if params[:permissions].is_a? Hash
      params[:permissions].each_pair do |role_id, rest|
        role = @instance.roles.find(role_id, :include => [:permissions, :privileges])
        rest.each_pair do |model_name, actions|
          to_delete = @perms_hash[model_name.gsub(/[a-z][A-Z]/) {|m| "#{m[0,1]} #{m[1,2]}"}] - actions.keys
          to_add = actions.keys - role.permissions.find_all_by_model(model_name).map(&:action)
          
          to_delete.each do |act|
            perm = role.permissions.find(:first, :conditions => {:model => model_name, :action => act})
            perm.privileges.find_by_role_id(role.id).destroy if perm
          end
          
          to_add.each do |act|
            role.permissions << Permission.find(:first, :conditions => {:model => model_name, :action => act})
          end

          role.save
        end
      end
    end
    if @instance.update_attributes(params[:instance])
      flash[:notice] = t('notice.instance_.updated')
      redirect_to edit_path(:id=>params[:instance][:id])
    else
      flash[:error] = t('error.instance.update_failed')
      render edit_path
    end
  end

  # Removes an instance object specified by its :id from the database
  def destroy
#    return with_rejection unless @current_user.can? :destroy => @instance
    return with_rejection unless ((@current_user && (@current_user.can? :destroy => @instance)) || Admin.current)
    @instance = Instance.find(Integer(params[:id]))
    @instance.destroy
    redirect_to instances_path
  end

  def new
  #  return with_rejection unless @current_user.can? :create => Instance
    return with_rejection unless ((@current_user && (@current_user.can? :create => @instance)) || Admin.current)
    @instance = Instance.new
  end

  # Saves an instance object to the database with the parameters provided in
  # the :instance hash, which is populated by the form on the 'new' page
  def create
  #  return with_rejection unless @current_user.can? :create => Instance
    return with_rejection unless ((@current_user && (@current_user.can? :create => Instance)) || Admin.current)
    @instance = Instance.create(params[:instance])
    @instance.short_name = params[:instance][:short_name]
    @instance.roles = Role.default_setup
    if @instance.save
      flash[:notice] = t('notice.instance_.created')
      redirect_to instances_path
    else
      render :action => 'new'
    end
  end


  protected
    def setup_editable_permissions
      crud = ['create', 'update', 'destroy']
      @perms_hash = { 'Update'      => crud,
                      'Comment'     => crud,
                      'User'        => crud,
                      'Group'       => crud,
                      'Group Type'  => crud,
                      'Incident'    => crud }
    end
end

