DiscussionBoardBackend::Application.routes.draw do
  
  match 'login' => 'sessions#create'
  match 'logout' => 'sessions#destroy'
  match 'signup' => 'users#create'
  
  resources :topics do
    resources :posts
  end
  
end
