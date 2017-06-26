class RecordActivitiesController < ApplicationController
  before_action :authorize

  def publish
    @resource = params[:record_to_publish_type].classify.constantize.find(params[:record_to_publish_id])

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

  def unpublish
    @resource = params[:record_to_publish_type].classify.constantize.find(params[:record_to_publish_id])
    @resource.record_activities.where(activity_type: 'Published').destroy_all
    
    respond_to do |format|
      format.html { redirect_to @resource, notice: 'Resource successfully unpublished.' }
      format.js
    end
  end 

end