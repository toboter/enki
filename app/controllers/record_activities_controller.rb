class RecordActivitiesController < ApplicationController
  before_action :authorize
  before_action :set_resource, only: [:update, :destroy]

  def update
    respond_to do |format|
      if !@resource.published? && @resource.record_activities.create(actor: current_user, activity_type: 'Published')
        format.html { redirect_to @resource, notice: 'Resource successfully published.' }
        format.js
      else
        format.html { render :new }
        format.js
      end
    end
  end 

  def destroy
    @resource.record_activities.where(activity_type: 'Published').destroy_all
    
    respond_to do |format|
      format.html { redirect_to @resource, notice: 'Resource successfully unpublished.' }
      format.js
    end
  end 

  def publish_multiple
    model_class = params[:model_class_name].classify.constantize

    if model_class.respond_to?(:filterrific)
      filterrific = initialize_filterrific(
        model_class.visible_for(current_user),
        params[:filterrific],
      ) or return

      results = filterrific.find
    elsif model_class.respond_to?(:searchkick)
      sk_results = model_class.visible_for(current_user).search (params[:search].presence || '*')
      results = model_class.where(id: sk_results.map(&:id))
    else
      results = model_class.visible_for(current_user)
    end

    results.in_batches.each do |records|
      if params[:state] == 'publish'
        values = records.map {|record| "(#{record.id},'#{record.class.base_class.name}',#{current_user.id},'Published',now(),now())" }
        ActiveRecord::Base.connection.execute("INSERT INTO record_activities (resource_id, resource_type, actor_id, \
          activity_type, created_at, updated_at) VALUES #{values.flatten.compact.to_a.join(",")}")  # ON CONFLICT DO UPDATE
        @state = 'published'
      elsif params[:state] == 'unpublish'
        RecordActivity.where(resource_id: records.ids, resource_type: model_class.name, activity_type: 'Published').delete_all
        @state = 'unpublished'
      else
        @state = 'not on publishing' 
      end
    end
    redirect_to url_for(model_class), notice: "Successfully #{@state} #{model_class.name.pluralize}."
  end

  private

    def set_resource
      klass = params[:resource_type].classify.constantize
      @resource = klass.respond_to?(:friendly) ? klass.friendly.find(params[:id]) : klass.find(params[:id])
    end

end