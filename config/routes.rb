Rails.application.routes.draw do
  root to: 'home#index'
  post 'download', to: 'home#download'
end
