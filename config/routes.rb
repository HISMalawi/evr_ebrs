Rails.application.routes.draw do
  get 'maternity/create_from_maternity'
  post 'maternity/create_from_maternity'

  get 'get_birth_report' => 'maternity#get_birth_report'
  post 'get_birth_report' => 'maternity#get_birth_report'
	
  get 'reports/index'

  get 'users/index'

  root 'person#index'

  get 'users/show'

  get 'users/view'

  get 'users/new'

  get 'users/create'

  get 'users/my_account'

  get '/users/change_keyboard'

  get "/users/update_keyboard"

  get '/person/get_sync_status'

  get "/block_user/:id" => "users#block_user"

  get "/unblock_user/:id" => "users#unblock_user"

  get "/void_user/:id" => "users#void_user"

  get '/block'  => "users#block"

  get '/unblock' => "users#unblock"

  get '/query_users' =>"users#query_users"

  get "/view" => "person#view"

  get "/view_users" => "users#view"

  get "/check_sync" => "person#check_sync"

  get "/dispatch_note" => "reports#dispatch_note"

  get "/view_dispatches" => "reports#view_dispatches"

  get "/dispatch_list" => "reports#dispatch_list"

  get 'users/my_account'

  post 'users/update_password'

  get 'users/change_password'

  get "/query" => "person#query"

  get "query_sync" =>"person#query_sync"


  get "/logout" => "logins#logout"

  get "/change_password" => "users#change_password"

  get "/login" => "logins#login"

  get "/search_by_fullname/:id" => "person#search_by_fullname"

  get "/search_by_name" => "person#search_by_name"

  get "/search_by_username" => "users#search_by_username"

  get "/set_context/:id" => "logins#set_context"

  get "/edit_account" => "users#edit_account"

  get 'person/index'

  get 'person/show'

  get 'person/new'

  get 'person/new_split'

  get 'person/barcode_scan'

  post 'person/create'

  get '/search_similar_record' => "person#search_similar_record"

  post '/application/get_registration_type'

  get 'records/:status' => 'person#records'

  get "view_sync" =>"person#view_sync"

  ##### printing routes
  get '/person/child_id_label'
  get '/person/reprint_child_id_label/:child_id' => 'person#reprint_child_id_label' # for reprinting
  # ------------------------

  ########################### (create record form) routes

  get '/new_registration' => "dc#new_registration"

  post "/person/:id" => "person#show", :defaults => { :next_path => "view_record"}

  get '/get_last_names' => 'person#get_names', :defaults => {last_name: 'last_name'}
  get '/get_first_names' => 'person#get_names', :defaults => {first_name: 'first_name'}
  get '/search_by_nationality' => 'person#get_nationality'
  get '/search_by_country' => 'person#get_country'
  get '/search_by_district' => 'person#get_district'
  get '/search_by_ta' => 'person#get_ta'
  get '/search_by_village' => 'person#get_village'
  get '/search_by_hospital' => 'person#get_hospital'
  ########################### (create record form) routes end

  get '/manage_cases' => "dc#manage_cases"
  get '/pending_cases' => "dc#manage_pending_cases"
  get '/manage_requests' => "dc#manage_requests"
  get '/manage_duplicates_menu' => "dc#manage_duplicates_menu"
  get '/view_duplicates' => "dc#view_duplicates"
  get "/view_hq_duplicates" => "dc#view_hq_duplicates"
  get "/potential/duplicate/:id" => "dc#potential_duplicate"
  get "/add_duplicate_comment/:id" => "dc#add_duplicate_comment"
  get "/resolve_duplicate" =>"dc#resolve_duplicate"
  get "/duplicates" => "dc#duplicates"

  get "/view_complete_cases" => "person#view_complete_cases"
  get "/view_incomplete_cases" => "person#view_incomplete_cases"

  get "/incomplete_case_comment/:id" => "dc#incomplete_case_comment"
  get "/complete_case_comment/:id" => "dc#complete_case_comment"
  get "/pending_case_comment/:id" => "dc#pending_case_comment"
  get "/reject_case_comment/:id" => "dc#reject_case_comment"

  get "/incomplete_case" => "dc#incomplete_case"
  get "/pending_case" => "dc#pending_case"
  get "/reject_case" => "dc#reject_case"

  ####################Pending cases routes ##################################
  get "/dc/manage_pending_cases"
  ###########################################################################

  ##############################Special Cases#################################
  get "/dc/special_cases"
  ############################################################################
  get "/view_cases" => "person#view_cases"
  get "/view_approved_cases" => "person#view_approved_cases"
  get "/view_pending_cases" => "person#view_pending_cases"
  get "/view_rejected_cases" => "person#view_rejected_cases"
  get "/view_hq_rejected_cases" => "person#view_hq_rejected_cases"

  get "/view_printed_cases" => "person#view_printed_cases"
  get "/view_voided_cases" => "person#view_voided_cases"
  get "/view_dispatched_cases" => "person#view_dispatched_cases"
  get "/ajax_approve/:id" => "dc#ajax_approve"

  get 'dc/abandoned_cases'
  get 'dc/orphaned_cases'
  get 'dc/adopted_cases'

  get 'person/lost_and_damaged_cases'
  get 'person/ammendment_cases'
  get 'person/rejected_ammendment_cases'
  get 'person/ammend_case'
  get '/person/amend_edit/:id'=> 'person#amend_edit'
  get '/person/amend_field'
  get '/person/amendiment_comment'
  get '/person/do_amend'
  get 'person/reprint_case'
  get 'person/do_reprint'
  get 'person/approve_reprint_request'
  get "person/approve_amendment_request"
  get '/search' => 'dc#search'
  get '/searched_cases' => 'person#searched_cases'
  post '/searched_cases' => 'person#searched_cases'


  get '/filter' => 'dc#filter'
  get '/rfilter' => 'dc#rfilter'

  get "/comments/:id" => 'dc#comments'

  get 'reports/births_report'
  get 'reports/report'
  get 'reports/report_date_range'
  get 'reports/filter'
  get 'reports/rfilter'
  get "/user_audit_trail" =>"reports#user_audit_trail"
  get "/get_user_audit_trail" => "reports#get_user_audit_trail"
  get '/update_person' => 'person#update_person'
  post '/update' => "person#update"

  get '/person/paginated_data'
  get '/person/paginated_search_data'
  get '/person/search_by_nid'

  resources :person

  resources :users

  resource :login do
    collection do
      get :logout
    end
  end
end
