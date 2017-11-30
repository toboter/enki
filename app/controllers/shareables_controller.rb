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

  def share_multiple
    accessors = params[:accessors] ? params[:accessors].map{ |a| a.split(' ').map{|b| b.strip } }.map{ |h| h.last.classify.constantize.find(h.first) }.compact : false
    editors = params[:can_edit] ? params[:can_edit].map{ |a| a.split(' ').map{|b| b.strip } }.map{ |h| h.last.classify.constantize.find(h.first) }.compact : false
    model_class = params[:model_class_name].classify.constantize

    if model_class.respond_to?(:filterrific)
      filterrific = initialize_filterrific(
        model_class.visible_for(current_user),
        params[:filterrific],
      ) or return

      results = filterrific.find
    elsif model_class.respond_to?(:searchkick)
      records = model_class.visible_for(current_user).all
      query = params[:search].presence || '*'
      if model_class.respond_to?(:filter)
        records = records.filter(params.slice(:with_user_shared_to_like, :with_unshared_records, :with_published_records))
      end

      sk_results = model_class.search(query, 
        where: { id: records.ids },
        per_page: 10000 ,
        misspellings: {below: 1}
        ) do |body|
          body[:query][:bool][:must] = { query_string: { query: query, default_operator: "and" } }
        end

      results = model_class.where(id: sk_results.map(&:id))

    else
      results = model_class.visible_for(current_user)
    end

    results.in_batches.each do |records|
      @values = []
      accessors.each do |accessor|
        can_edit = editors ? (editors.include?(accessor) ? true : false) : false
        @values << records.map {|record| "(#{accessor.id},'#{accessor.class.name}',#{record.id},'#{record.class.base_class.name}',#{current_user.id},'#{current_user.class.name}',#{can_edit},now(),now())" }
      end

      ActiveRecord::Base.connection.execute("INSERT INTO share_models (shared_to_id, shared_to_type, resource_id, resource_type, \
        shared_from_id, shared_from_type, edit, created_at, updated_at) VALUES #{@values.flatten.compact.to_a.join(",")} ON CONFLICT (resource_id, resource_type, shared_to_id, shared_to_type) DO NOTHING") # ON CONFLICT DO UPDATE
    end
    redirect_to url_for(model_class), notice: "Successfully shared #{model_class.name.pluralize}."
  end

  def unshare_multiple
    @accessors = params[:accessors]
    model_class = params[:model_class_name].classify.constantize

    if model_class.respond_to?(:filterrific)
      filterrific = initialize_filterrific(
        model_class.visible_for(current_user),
        params[:filterrific],
      ) or return

      results = filterrific.find
    elsif model_class.respond_to?(:searchkick)
      records = model_class.visible_for(current_user).all
      query = params[:search].presence || '*'
      if model_class.respond_to?(:filter)
        records = records.filter(params.slice(:with_user_shared_to_like, :with_unshared_records, :with_published_records))
      end

      sk_results = model_class.search(query, 
        where: { id: records.ids },
        per_page: 10000 ,
        misspellings: {below: 1}
        ) do |body|
          body[:query][:bool][:must] = { query_string: { query: query, default_operator: "and" } }
        end

      results = model_class.where(id: sk_results.map(&:id))

    else
      results = model_class.visible_for(current_user)
    end
    

    @acc_instances =[]
    @accessors.each do |accessor|
      acc_hash = accessor.split(' ').map{|a| a.strip }
      @acc_instances << acc_hash.last.classify.constantize.find(acc_hash.first)
    end

    results.in_batches.each do |records|
      ShareModel.where(shared_to: @acc_instances, resource_id: records.ids, resource_type: model_class.name).delete_all
    end

    redirect_to url_for(model_class), notice: 'Accessors successfully removed.'
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
