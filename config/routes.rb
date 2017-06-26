Rails.application.routes.draw do
  resources :shareables, only: [:new, :create, :edit, :update, :destroy] do
    collection do
      put :add_multiple
      delete :remove_multiple
    end
  end

  resources :record_activities, only: [] do
    collection do
      post :publish
      delete :unpublish
    end
  end

end
