Rails.application.routes.draw do
  resources :shareables, only: [:new, :create, :edit, :update, :destroy] do
    collection do
      post :share_multiple
      delete :unshare_multiple
    end
  end

  resources :record_activities, only: [:update, :destroy] do
    collection do
      post :publish_multiple
    end
  end

end
