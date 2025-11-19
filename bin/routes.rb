require 'sidekiq/web'
require 'sidekiq/cron/web'

Rails.application.routes.draw do

  mount Ckeditor::Engine => '/ckeditor'
  get 'test', to: 'application#test'
  get 'test_push_notification', to: 'application#test_push_notification'
  post 'appsflyer/installation'

  # Need to recheck these routes
  get 'business/enroll_company'
  get 'business/verify'
  get 'business/choose_account'
  post 'business/enroll_company_submit'


  get 'edit_password/edit'
  put 'edit_password/update'

  # mount RailsAdmin::Engine => '/rails_admin', as: 'rails_admin'
  # mount GrapeSwaggerRails::Engine => '/swagger' unless Rails.env.production?

  authenticate :staff do
    mount Sidekiq::Web, at: '/sidekiq'
  end

  authenticate :staff, lambda{|user| user.has_feature_key?('report_management') } do
    mount Blazer::Engine, at: "blazer"
  end

  mount API::Root => '/'
  mount API::PublicRoot => '/'
  mount API::CargopediaRoot => '/'
  mount API::FpdV1Root => '/'
  mount API::InternalRoot => '/'
  mount API::HalRoot => '/'
  mount API::TallyV1Root => '/'
  mount API::IntegrationRoot => '/'
  mount API::MaritimeRoot => '/'
  mount API::InternalQcRoot => '/'

  devise_for :customers,
    controllers: {
      sessions: "customers/sessions",
      registrations: "customers/registrations",
      passwords: "customers/passwords"
    }

  devise_for :staffs,
    controllers: {
      sessions: :sessions,
      registrations: :registrations,
      passwords: :passwords
    }

  get "/auth/:action/callback", :to => "authentications", :constraints => { :action => /facebook|google_oauth2/ }

  resources :customers, only: [:update] do
    put :update_password, on: :member
    patch :update_identity, on: :member
    put 'settings' => "customers#update_settings", on: :member
    collection do
      get :merge
      get :hotline_current_customer
      get :get_authentication_token
      get :get_chat_token
      get :reload_top_nav_after_sign_in
      get :check_company_approved_notification
      get :update_customer_menu
      put :clear_company_approved_notification
    end
  end
  resources :credit_balances, only: [:index] do
    collection do
      get :topup
      post :handle_top_up_redirect
      get :handle_top_up_redirect
    end
  end
  resources :preference_drivers, only: [:index]

  namespace :admin, module: "admin", path: '/', constraints: {subdomain: /^admin/} do
    root to: 'bookings#index'
    get 'dashboard' => 'dashboard#index'
    get 'settings' => 'settings#index'
    get 'settings/map' => 'settings#map'
    get 'settings/edit' => 'settings#edit'
    get 'settings/view_history' => 'settings#view_history'
    put 'settings/update' => 'settings#update'
    put 'settings/update_all' => 'settings#update_all'
    post 'settings/upload_map' => 'settings#upload_map'
    resources :settings_features, only: [:index] do
      collection do
        get :tally
        get :new_gen_cpod
        get :km_range
        put :update_km_range
        put :update
        get :wallee_redirect
        put :update_wallee_redirect
      end
    end

    resources :staffs, path: '/admin_staffs' do
      collection do
        put "set_current_area_id"
        get :edit_password
        put :update_password
        put :validate_all_pending_payment
        get :me
        get :get_authentication_token
      end
      get 'view_history', on: :member
    end
    resources :drivers, path: '/admin_drivers' do
      get 'settings' => "drivers#settings", on: :member
      put 'settings' => "drivers#update_settings", on: :member
      get 'check_device', on: :member
      post 'set_new_device', on: :member
      get 'booking_statistic', on: :member
      get 'suspension_history', on: :member
      get 'uberized_history', on: :member
      get 'render_vehicle_attributes', on: :member
      get 'view_history', on: :member
      get 'vehicle_history', on: :member
      get 'chat_history', on: :member
      get 'working_schedule', on: :member
      put 'confirm_transactions', on: :member
      # get 'dashboard', on: :collection
      get 'info', on: :member
      get 'edit_reimbursement', on: :member
      put 'update_reimbursement', on: :member
      get 'autocomplete', on: :collection
      get 'online', on: :collection
      get 'settings/edit' => "drivers#edit_setting", on: :member
      get 'settings/view_history' => "drivers#setting_view_history", on: :member
      put 'settings/update' => "drivers#update_setting", on: :member
      get 'check_approve_status', on: :member
      resources :credit_transactions, controller: :driver_credit_transactions, only: [:index, :new, :create, :update] do
        post 'withdraw', on: :member
        get 'security_bond', on: :collection
        get 'render_sub_category_partial', on: :collection
        get 'shopping_fund', on: :collection
        get 'pending_payments', on: :collection
      end
      resources :watch_sets, controller: :driver_watch_sets
    end
    resources :customers, path: '/admin_customers' do
      get 'autocomplete', on: :collection
      get 'autocomplete_drivers', on: :member
      get 'autocomplete_vehicle_types', on: :member
      get 'approved_vehicle_types', on: :member
      get 'accepted_drivers', on: :member
      get 'approved_drivers', on: :member
      get 'booking_statistic', on: :member
      get 'settings' => "customers#settings", on: :member
      get 'settings/edit' => "customers#edit_setting", on: :member
      get 'settings/view_history' => "customers#setting_view_history", on: :member
      put 'settings/update' => "customers#update_setting", on: :member
      get 'require_signatures' => "customers#get_require_signatures", on: :member
      put 'settings' => "customers#update_settings", on: :member
      get 'view_history', on: :member
      get 'sub_account_tags', on: :member
      get 'customer_driver_history', on: :member
      put 'send_email_reset_password', on: :member
      put 'send_sms_reset_password', on: :member
      resources :credit_transactions, controller: :customer_credit_transactions, only: [:index, :new, :create] do
        get 'waive_off_settlements', on: :collection
        get 'render_sub_category_partial', on: :collection
      end

      resources :locations, controller: 'contacts', as: 'contacts' do
        collection do
          post "import"
          get 'download_template'
          delete "destroy_contacts"
        end
      end
      resources :surcharge_pricings, :path => 'charge_types'
    end
    resources :import_credit_transactions, only: [:index, :show, :new, :create]
    resources :customer_groups, path: '/admin_customer_groups' do
      get 'autocomplete/:account_type' => 'customer_groups#autocomplete', on: :collection, as: :autocomplete
    end
    resources :bannedapps, path: '/admin_bannedapps', controller: :banned_apps do
      get 'autocomplete', on: :collection
      get 'view_history', on: :member
    end
    resources :remarks, only: [:index, :new, :create, :update, :destroy]
    resources :retraining_logs, only: [:index, :new, :create, :update, :destroy]
    resources :sub_account_tags, only: [:index, :create, :update] do
      collection do
        get 'autocomplete/:taggable_type/:taggable_id' => 'sub_account_tags#autocomplete', as: :autocomplete
        get 'sort_by_name/:taggable_type/:taggable_id' => 'sub_account_tags#sort_by_name', as: :sort_by_name
        put 'sort'
      end
      member do
        post 'pair' => "sub_account_tags#pair"
        delete 'pair' => "sub_account_tags#unpair"
      end
    end
    resources :active_sites, only: [:create, :update]
    resources :discounts
    resources :service_types do
      resources :popups, controller: :service_type_popups
      get 'settings' => "service_types#settings", on: :member
      put 'settings' => "service_types#update_settings", on: :member
      get 'settings/edit' => "service_types#edit_setting", on: :member
      get 'settings/view_history' => "service_types#setting_view_history", on: :member
      put 'settings/update' => "service_types#update_setting", on: :member
      get 'vehicle_type_collection' => 'service_types#vehicle_type_collection', on: :member
    end
    resources :vehicle_attributes
    resources :vehicle_types do
      resources :surcharge_pricings
      resources :popups, controller: :vehicle_type_popups
      resources :dynamic_texts, controller: :vehicle_type_dynamic_texts
      resources :footnotes, controller: :vehicle_type_footnotes
      resources :extra_requirement_vehicle_types do
        get 'settings' => "extra_requirement_vehicle_types#settings", on: :member
        put 'settings' => "extra_requirement_vehicle_types#update_settings", on: :member
      end
      resources :vehicle_type_badges
      member do
        get 'settings' => 'vehicle_types#settings'
        put 'settings' => 'vehicle_types#update_settings'
        get 'settings/edit' => "vehicle_types#edit_setting"
        get 'settings/view_history' => "vehicle_types#setting_view_history"
        put 'settings/update' => "vehicle_types#update_setting"
        get 'quick_choices' => 'vehicle_types#quick_choices'
        put 'quick_choices' => 'vehicle_types#update_quick_choices'
        get 'coding_day' => 'vehicle_types#coding_day_rule'
        put 'coding_day' => 'vehicle_types#coding_day_rule'
        get 'time_type_explanations' => 'vehicle_types#time_type_explanations'
        put 'time_type_explanations' => 'vehicle_types#update_time_type_explanations'
        get 'view_history' => 'vehicle_types#view_history'
        get 'pricing_rules_history' => 'vehicle_types#pricing_rules_history'
        get 'radius_settings' => 'vehicle_types#radius_settings'
        put 'radius_settings' => 'vehicle_types#update_radius_settings'
      end
      resources :long_haul_areas
      get 'long_haul_prices' => "long_haul_prices#index", on: :member
      put 'long_haul_prices' => "long_haul_prices#update", on: :member
      resources :vehicle_type_reimbursements, as: 'reimbursements', only: [:index, :new, :create]
      resources :devina_rules do
        collection do
          put 'sort'
        end
      end
      resources :vendor_tippings, except: [:show] do
        get 'view_history', on: :collection
      end
      get 'render_partial_saver_standard_id' => 'vehicle_types#render_partial_saver_standard_id', on: :collection
    end
    resources :vehicle_type_reimbursements, as: 'reimbursements', only: [:show, :edit, :update, :destroy] do
      resources :popups, controller: :vehicle_type_reimbursement_popups, shallow: true
    end
    resources :extra_requirement_vehicle_types do
      resources :popups, controller: :extra_requirement_vehicle_type_popups
    end
    resources :vehicle_type_mappings do
      get 'view_history', on: :member
    end
    resources :vehicle_type_groups, except: [:destroy]
    resources :extra_requirements
    resources :vehicles do
      collection do
        get 'autocomplete'
      end
    end
    resources :bookings do
      post 'assign', on: :member
      get 'view_history', on: :member
      get 'price_data', on: :member
      get 'chat_history', on: :member
      get 'chat_with_fleet_history', on: :member
      get 'chat_recipient_and_driver_history', on: :member
      get 'chat_recipient_and_booker_history', on: :member
      get 'render_list_extra_requirements', on: :member
      get 'render_attachments', on: :collection
      get 'render_upload_reimbursement_photo_item', on: :collection
      get 'render_upload_static_reimbursement_photo_item', on: :collection
      get 'render_upload_pod_photo_item', on: :collection
      get 'settings_vehicle_type', on: :collection
      put 'update_credit', on: :member
      put 'force_timeout', on: :member
      put 'update_note', on: :member
      put 'decline_recovery', on: :member
      put 'cancel_tms', on: :member
      get 'similar' => "bookings#new_similar", on: :member
      post 'similar' => "bookings#create_similar", on: :member
      get 'recover' => "bookings#new_recover", on: :member
      # post 'recover' => "bookings#create_similar", on: :member
      post 'send_recipient' => "bookings#send_recipient", on: :member
      get 'filter', on: :collection
      get 'relocating', on: :member
      # get 'around_driver', on: :member
      get 'driver_cancel_penalty', on: :member
      get 'unverified_arrived_location', on: :member
      get 'decline_delivery', on: :member
      get 'show_custom_reimbursements', on: :member
      get 'show_static_reimbursements', on: :member
      # # test
      # get 'test', on: :collection
      put 'pod_tracking', on: :member
      put 'cancel_as_driver', on: :member
      get 'customer_reason', on: :member
      put 'cancel_as_customer', on: :member
      put 'revert_settlement_as_customer', on: :member
      put 'mark_unverified_arrived', on: :member
      get 'order', on: :member
      put 'update_cancellation_reasons', on: :member
      post 'check_total_fee_change_booking', on: :member
      post 'check_booking_full_day_out_of_radius', on: :member
    end
    resources :event_notifications
    resources :tolls_parking_approvals
    # resources :notifications do
    #   get :test, on: :collection
    #   post :do_test, on: :collection
    # end
    get 'reports/kpi_driver'
    get 'reports/kpi_customer'

    resources :articles
    resources :version_trackings
    resources :area_groups
    resources :long_haul_area_groups
    resources :areas do
      resources :dynamic_texts
      resources :popups, controller: :area_popups
      get 'area_groups', on: :collection
    end
    get 'anti_spam_settings' => "areas#anti_spam_settings"
    put 'anti_spam_settings' => "areas#update_anti_spam_settings"
    put 'anti_spam_setting' => "areas#update_anti_spam_setting"
    get 'anti_spam_setting_history' => "areas#anti_spam_setting_history"
    get 'fleet_partner_settings' => "areas#fleet_partner_settings"
    put 'fleet_partner_settings' => "areas#update_fleet_partner_settings"
    put 'fleet_partner_setting' => "areas#update_fleet_partner_setting"
    get 'fleet_partner_setting_history' => "areas#fleet_partner_setting_history"
    patch 'update_area_attachments' => "areas#update_area_attachments"
    resources :roles, except: [:show] do
      get "feature_checkboxes", on: :member
    end
    resources :service_explainations
    resources :companies, except: [:destroy] do
      get 'autocomplete', on: :collection
      get 'companies_drivers_autocomplete', on: :collection
      get 'autocomplete_booking_drivers', on: :member
      get 'autocomplete_vehicle_types', on: :member
      get 'approved_vehicle_types', on: :member
      get 'accepted_drivers', on: :member
      get 'dedicated_drivers', on: :member
      get 'approved_drivers', on: :member
      get 'view_history', on: :member
      get 'sub_account_tags', on: :member
      get 'customer_driver_history', on: :member
      resources :locations, controller: 'contacts', as: 'contacts' do
        collection do
          post "import"
          get 'download_template'
          delete "destroy_contacts"
        end
      end
      resources :employs
      resources :company_badges do
        get 'badge_drivers', on: :member
      end
      resources :credit_transactions, controller: :company_credit_transactions, only: [:index, :new, :create] do
        put "reset_limit_counter", on: :collection
        get 'render_sub_category_partial', on: :collection
      end
      get 'settings' => "companies#settings", on: :member
      put 'settings' => "companies#update_settings", on: :member
      get 'settings/edit' => "companies#edit_setting", on: :member
      get 'settings/view_history' => "companies#setting_view_history", on: :member
      put 'settings/update' => "companies#update_setting", on: :member
      resources :surcharge_pricings, :path => 'charge_types'
    end

    resources :company_types do
      get 'settings' => "company_types#settings", on: :member
      put 'settings' => "company_types#update_settings", on: :member
      get 'settings/view_history' => "company_types#setting_view_history", on: :member
      put 'settings/update' => "company_types#update_setting", on: :member
    end

    resources :contacts do
      delete "destroy_contacts", on: :collection
    end

    resources :devices, only: [:index]

    resources :badges

    resources :custom_reimbursements

    resources :devina_rules do
      get 'view_history', on: :member
      get 'get_max_cap', on: :member
      resources :devina_stages do
        collection do
          put 'sort'
        end
      end
    end

    resources :action_reasons do
      collection do
        post "import"
        get "download_template"
        # get 'render_partial_ptl_reasons'
      end
    end
    resources :contacts, path: '/admin_contacts' do
      get "autocomplete", on: :collection
      put "re_update", on: :member
    end
    resources :fleet_partners do
      get 'suspension_history', on: :member
      get 'view_history', on: :member
      get 'uberized_history', on: :member
      get 'edit_reimbursement', on: :member
      put 'update_reimbursement', on: :member
      resources :fleet_accounts, controller: :fleet_partner_accounts
      resources :credit_transactions, controller: :fleet_partner_credit_transactions,
        only: [:index, :new, :create, :update] do
          get 'pending_payments', on: :collection
        end
      resources :drivers, controller: :fleet_partner_drivers, only: %i[index new update destroy] do
        get 'approval', on: :collection
        post 'approval_drivers', on: :collection
      end
      resources :vehicles, controller: :fleet_partner_vehicles, only: [:index, :new, :create, :edit, :update, :destroy, :show] do
        member do
          get 'render_vehicle_attributes'
          put 'unpair'
        end
        get 'approval', on: :collection
        post 'approval_vehicles', on: :collection
      end
      resources :watch_sets, controller: :fleet_partner_watch_sets do
        get 'render_time_types', on: :collection
        get 'render_extra_requirements', on: :collection
      end
    get 'settings' => "fleet_partners#settings", on: :member
    put 'settings' => "fleet_partners#update_settings", on: :member
    get 'settings/view_history' => "fleet_partners#setting_view_history", on: :member
    put 'settings/update' => "fleet_partners#update_setting", on: :member
    end

    resources :driver_penalties
    resources :customer_penalties
    resources :hotlines
    resources :area_attachments
    resources :vehicle_type_make_models
    resources :vehicle_makes
    resources :vehicle_models
    resources :provinces
    resources :districts

    resources :driver_onboarding_menus, path: '/admin_driver_onboarding_menus'
    resources :global_attributes
    resources :areas_attributes do
      get :add_new_attribute, on: :collection
      get :settings, on: :member
      put :update_settings, on: :member
    end
    resources :driver_onboardings do
      get :view_history, on: :member
      post :change_approve_status, on: :member
      get :verify_info, on: :member
      put :update_verify_info, on: :member
      post :send_training_link, on: :member
      get :get_verify_info_attributes, on: :member
      put :update_verify_info_attributes, on: :member
      put :staff_assigned, on: :member
      put :mark_on_hold, on: :member
      get :photo_versions, on: :member
      post :resend_retraining_sms, on: :collection
      get :render_vehicle_attributes, on: :member
    end
    resources :driver_onboarding_reasons
    resources :driver_onboarding_exams, except: [:show] do
      get :settings, on: :member
      post :update_settings, on: :member
    end
    resources :import_tracking_codes, only: [:index, :show, :new, :create] do
      collection do
        post :validate
      end
    end
    resources :transit_time_rules, except: [:show]
    resources :ferry_kml_settings
    resources :traffic_buffers, only: [:index] do
      collection do
        get :edit
        put :update
      end
    end
    resources :coc_profiles, only: [:index, :new, :create, :edit, :update, :show] do
      resources :coc_accounts, only: [:index, :new, :create, :edit, :update, :show, :destroy]
      member do
        get 'settings' => "coc_profiles#settings"
        put 'settings' => "coc_profiles#update_settings"
      end
    end
    resources :dynamic_icons, except: [:show]
    resources :sub_accounts, only: [:index, :new, :create, :edit, :update]
    resources :cash_back_rewards
    resources :cut_off_times
    resources :badge_accreditations do
      get 'render_list_services', on: :collection
    end
    resources :internal_batch_uploads, only: [:index, :new, :show] do
      collection do
        post 'handle_internal_batch_upload/:item_type' => 'internal_batch_uploads#handle_internal_batch_upload', as: :handle_internal_batch_upload
        get 'download_template/:item_type' => 'internal_batch_uploads#download_template', as: :download_template
        get 'render_driver_fields' => 'internal_batch_uploads#render_driver_fields', as: :render_driver_fields
      end
      get 'view_history', on: :member
    end
  end

  # resources :api_dashboards, only: [:index] do
  #   collection do
  #     put :update_api_key
  #     put :update_webhook_url
  #     put :update_webhook_authentication_key
  #     put :update_webhook_content_type

  #     unless Rails.env.production?
  #       get :test_my_bookings
  #       get :test_booking
  #       get :cancle_booking
  #     end
  #   end
  # end

  namespace :business do
    get "choose_account"
    put "switch_account"
    get "select_area"
    put "switch_area"
    put "change_language"
    get 'enroll_company'
    post 'enroll_company_submit'
    get 'verify'
    get :set_new_current_area_session
    get :set_new_language_session
    get :get_current_language_session

    resources :employees, as: :employs do
      get "accept/:invitation_token" => "employees#accept", on: :collection, as: :accept
      get "after_accept", on: :collection
      put "change_role/:role"  => "employees#change_role", on: :member, as: :change_role
      put "resend_invite", on: :member
      delete "destroy_list", on: :collection
    end

    # resources :contacts do
    #   collection do
    #     post "import"
    #     get "download_template"
    #     put "delete_contacts"
    #   end
    # end

    resources :credit_balances, only: [:index] do
      collection do
        get :topup
        get :handle_top_up_redirect
        post :handle_top_up_redirect
      end
    end

    resources :booking_invoice, only: [] do
      collection do
        get :printable
      end
    end

    resources :api_dashboards, only: [:index] do
      collection do
        patch :update_webhook
        put :update_api_key
        put :update_webhook_url
        put :update_webhook_authentication_key
        put :update_webhook_content_type

        unless Rails.env.production?
          get :test_my_bookings
          get :test_booking
          get :cancle_booking
        end
      end
    end
  end

  resources :locations, controller: 'contacts', as: 'contacts' do
    collection do
      post "import"
      get "download_template"
      put "delete_contacts"
    end
  end

  resources :bookings, except: [:create, :update, :destroy] do
    collection do
      get "multiple"
      get 're_convert_token'
    end
    member do
      put "update_favorite_status"
      get "tracking"
      get "share"
      get "follow"
      get "book_again"
      get "pod_cod"
      get 'proof_of_delivery'
      get "download_goods_pictures", :as => :download
      get "verify_reimbursements"
      get "render_details"
    end

    collection do
      get "booking_locations"
      get "booking_price"
      get "booking_note"
      get "booking_attachments"
      get "booking_signatures"
      get "booking_driver_note"
      get "driver_rate_dialog"
      put "customer_rate_driver_booking"
      put "update_customer_driver_reference"
      get "booking_reimbursement"
      get "tracking_url"
      put "reimbursement_confirm"
    end
  end

  resources :draft_bookings, only: [:index, :destroy] do
    collection do
      delete :destroy_all
    end
  end

  resources :batches, only: [:index, :show] do
    collection do
      get :select
      get :ez_spread_sheet
      get :smart_load_planner
    end
  end

  resources :dashboard_analytics, only: [:index] do
    collection do
      get 'download_analytics_attachment'
    end
  end

  resources :booking_attachments

  get 'home' => 'application#home'

  # landing page for before launch time
  get 'customer_terms_privacy' => 'application#customer_terms_privacy'
  get 'driver_terms_privacy' => 'application#driver_terms_privacy'
  get 'customer_help' => 'application#customer_help'
  get "service_explaination" => 'areas#service_explaination'

  post 'tracking_fcm_token' => 'application#tracking_fcm_token'

  get '/' => 'bookings#new', as: :webapp
  root 'application#index'
end
