module ShareablesHelper
  def shared_with(obj)
    render partial: 'shareables/list', locals: {obj: obj} # if !obj.published?
  end

  def share_multiple_with(model)
    render partial: 'shared/record_access_settings', locals: {model: model} # if !obj.published?
  end
end
