Rails.application.routes.draw do
  root 'home#index'
  get 'accounts/:account_id/transactions' => 'transactions#index', as: :account_transactions
  get 'accounts/:account_id/transactions/:from-:to' => 'transactions#range'
  post 'accounts/:account_id/transactions/report-income' => 'transactions#report_income'
  post 'accounts/:account_id/transactions/report-expence' => 'transactions#report_expence'
  post 'accounts/:account_id/transactions/report-refund' => 'transactions#report_refund'
  post 'accounts/:account_id/transactions/report-transfer' => 'transactions#report_transfer'
  post 'transactions/:transaction_id/adjust-ammount' => 'transactions#adjust_ammount'
  post 'transactions/:transaction_id/adjust-tags' => 'transactions#adjust_tags'
  post 'transactions/:transaction_id/adjust-date' => 'transactions#adjust_date'
  post 'transactions/:transaction_id/adjust-comment' => 'transactions#adjust_comment'
  delete 'transactions/:transaction_id' => 'transactions#destroy'
  
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
