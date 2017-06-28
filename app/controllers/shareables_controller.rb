class ShareablesController < ApplicationController
  before_action :authorize
  before_action :set_shareable, only: [:edit, :update, :destroy]

  def new
  end

  def create
    resource_klass = params[:resource_type].classify.constantize
    @resource = resource_klass.find(params[:resource_id])
    share_to = eval(params[:share_to])
    share_to_klass = share_to.first.classify.constantize
    @share_to = share_to_klass.find(share_to.last)

    respond_to do |format|
      if @resource.share_it(current_user, @share_to, edit)
        format.html { redirect_to @resource, notice: 'Share was successfully created.' }
        format.js
      else
        format.html { render :new }
        format.js
      end
    end
  end

  def edit
  end

  def update
    respond_to do |format|
      if @shareable.update(shareable_params)
        format.html { redirect_to @shareable.resource, notice: 'Share was successfully updated.' }
        format.js
      else
        format.html { render :edit }
        format.js
      end
    end
  end

  def destroy
    @shareable.resource.throw_out(current_user, @shareable.shared_to)
    respond_to do |format|
      format.html { redirect_to @shareable.resource, notice: 'Share was successfully destroyed.' }
      format.js
    end
  end

  def add_multiple
    @editing_accessors = params[:can_edit]
    @accessors = params[:accessors]
    @model_class = params[:model_class_name].classify.constantize

    if @model_class.respond_to?(:filterrific)
      @filterrific = initialize_filterrific(
        @model_class.visible_for(current_user),
        params[:filterrific],
      ) or return
    end

    (@filterrific.present? ? @filterrific.find : @model_class).in_batches.each do |records|
      values =[]
      @accessors.each do |accessor|
        can_edit = @editing_accessors ? (@editing_accessors.include?(accessor) ? true : false) : false
        acc_hash = accessor.split(' ').map{|a| a.strip }
        acc_instance = acc_hash.last.classify.constantize.find(acc_hash.first)
        values << records.map {|record| "(#{acc_instance.id},'#{acc_instance.class.name}',#{record.id},'#{record.class.base_class.name}',#{current_user.id},'#{current_user.class.name}',#{can_edit},now(),now())" }
      # Alle records, die nicht schon shared sind werden hinzugefügt
      # multi publish
      # multi unpublish
      # roles
      # record states: created draft(shared_to) review(shared_to says ready) published(by admin)
      # notifications send to babili
      end
      # raise values.flatten.compact.to_a.join(",").inspect
      ActiveRecord::Base.connection.execute("INSERT INTO share_models (shared_to_id, shared_to_type, resource_id, resource_type, shared_from_id, shared_from_type, edit, created_at, updated_at) VALUES #{values.flatten.compact.to_a.join(",")}")
    end
    redirect_to url_for(@model_class), notice: "Successfully shared #{@model_class.name.pluralize}."
  end

  def remove_multiple
    @accessors = params[:accessors]
    @model_class = params[:model_class_name].classify.constantize

    if @model_class.respond_to?(:filterrific)
      @filterrific = initialize_filterrific(
        @model_class.visible_for(current_user),
        params[:filterrific],
      ) or return
    end

    @acc_instances =[]
    @accessors.each do |accessor|
      acc_hash = accessor.split(' ').map{|a| a.strip }
      @acc_instances << acc_hash.last.classify.constantize.find(acc_hash.first)
    end

    (@filterrific.present? ? @filterrific.find : @model_class).in_batches.each do |records|
      ShareModel.where(shared_to: @acc_instances, resource_id: records.ids, resource_type: @model_class).delete_all
    end

    redirect_to url_for(@model_class), notice: 'Accessors successfully removed.'
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_shareable
      @shareable = ShareModel.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def shareable_params
      params.require(:shareable).permit(:filterrific, :resource_type, :resource_id, :shared_to, :edit, :share_to_children)
    end

end
