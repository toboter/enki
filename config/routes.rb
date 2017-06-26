Rails.application.routes.draw do
  resources :shareables, only: [:new, :create, :edit, :update, :destroy] do
    collection do
      put :add_multiple
      delete :remove_multiple
    end
  end
end
