DiscussionBoardBackend::Application.routes.draw do
  
  match 'login' => 'users#login'
  match 'signup' => 'users#signup'
  
  resources :topics
  
end
