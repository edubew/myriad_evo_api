Rails.application.routes.draw do
  namespace :api do
    namespace :v1 do
      devise_for :users,
      path: '',
      path_names: {
        sign_in: 'login',
        sign_out: 'logout',
        registration: 'register'
      },
      controllers: {
        sessions: 'api/v1/sessions',
        registrations: 'api/v1/registrations'
      }

      resources :events
      resources :clients do
        resources :contacts, only: [:create, :update, :destroy]
      end
      resources :projects do
        resources :tasks, only: [:create, :update, :destroy] do
          collection do
            post :reorder
          end
        end
      end
    end
  end
end
