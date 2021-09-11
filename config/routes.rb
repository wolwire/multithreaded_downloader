# frozen_string_literal: true

Rails.application.routes.draw do
  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
  root :to => "downloader#index"
  mount ActionCable.server, at: '/cable'
  resources :downloader, only: [:index] do
    collection do
      post :add_download
    end
  end
end
