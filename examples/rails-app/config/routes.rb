RailsApp::Application.routes.draw do

  root 'welcome#index'

  get  'login'  => 'sessions#new'
  post 'login'  => 'sessions#create'
  get  'logout' => 'sessions#destroy'

  get  'signup' => 'users#new'
  post 'signup' => 'users#create'

end
