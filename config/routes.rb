Rails.application.routes.draw do
  root 'home#index'
  
  resources :ledgers, only: [] do
    get 'currency-rates'
    resources :accounts, only: [:new, :create, :destroy], param: :account_id do
      post 'close', on: :member
      post 'reopen', on: :member
      put 'set-category', on: :member
    end
    
    resources :tags, only: [:create, :update, :destroy], param: :tag_id
    resources :categories, only: [:create, :update, :destroy], param: :category_id
  end
  resources :accounts, only: [], param: :aggregate_id do
    put 'rename', on: :member
  end
  resources :accounts, only: [] do
    resources :transactions, only: [:index] do
      post 'report-income', 'report-expence', 'report-refund', 'report-transfer', on: :collection
      get ':from-:to' => 'transactions#search', on: :collection
      post ':from-:to' => 'transactions#search', on: :collection
    end
  end
  
  resources :transactions, only: [:destroy] do
    post 'adjust-amount', 'adjust-tags', 'adjust-date', 'adjust-comment'
  end
  
  devise_for :users
  # The priority is based upon order of creation: first created -> highest priority.
  # See how all your routes lay out with "rake routes".

  # You can have the root of your site routed with "root"
  # root 'welcome#index'

  # Example of regular route:
  #   get 'products/:id' => 'catalog#view'

  # Example of named route that can be invoked with purchase_url(id: product.id)
  #   get 'products/:id/purchase' => 'catalog#purchase', as: :purchase

  # Example resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

  # Example resource route with options:
  #   resources :products do
  #     member do
  #       get 'short'
  #       post 'toggle'
  #     end
  #
  #     collection do
  #       get 'sold'
  #     end
  #   end

  # Example resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Example resource route with more complex sub-resources:
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', on: :collection
  #     end
  #   end

  # Example resource route with concerns:
  #   concern :toggleable do
  #     post 'toggle'
  #   end
  #   resources :posts, concerns: :toggleable
  #   resources :photos, concerns: :toggleable

  # Example resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end
  
  mount JasmineRails::Engine => '/specs' if defined?(JasmineRails)
end
