Rails.application.routes.draw do
  root 'static_pages#top'
  get '/signup', to: 'users#new'

  # ログイン機能
  get    '/login', to: 'sessions#new'
  post   '/login', to: 'sessions#create'
  delete '/logout', to: 'sessions#destroy'
  
  # 拠点情報
  resources :bases
  
  resources :users do
    collection { post :import }
    member do
      get 'edit_basic_info'
      patch 'update_basic_info'
      # 1ヶ月の変更申請
      get 'attendances/edit_one_month'
      patch 'attendances/update_one_month' # この行が追加対象です。
      # 1ヶ月の勤怠申請
      patch 'attendances/update_manager_approval_request'
      # 勤怠の確認
      get 'show_confirmation'
      # 出勤社員一覧
      get 'list_of_commuting_employees'
    end
    
    resources :attendances, only: :update do
      member do
        # 残業申請
        get 'edit_overtime_request'
        patch 'update_overtime_request'
        # 残業承認
        get 'edit_overtime_notice'
        patch 'update_overtime_notice'
        # 勤怠承認
        get 'edit_attendance_change_notice'
        patch 'update_attendance_change_notice'
        # 所属長承認
        get 'edit_manager_approval_notice'
        patch 'update_manager_approval_notice'
        # 勤怠修正ログ
        get 'attendance_log'
      end
    end
  end
end