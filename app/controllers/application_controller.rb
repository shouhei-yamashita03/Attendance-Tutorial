class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception
  include SessionsHelper

  $days_of_the_week = %w{日 月 火 水 木 金 土}

  # beforフィルター

  # paramsハッシュからユーザーを取得
  # 重複している部分をメソッド化
  # (params[:id])と(params[:user_id])の違いはパラメーターの違い(Routesを確認すれば分かる)
  def set_user
    @user = User.find(params[:id])
  end
  
  def set_user_id
    @user = User.find(params[:user_id])
  end
  
  def set_attendance
    @attendance = Attendance.find(params[:id])
  end
  
  def set_superior 
    @superiors = User.where(superior: true).where.not(id: @user.id)
  end
  
  # store_location ユーザがサイイン後、特定のパスにリダイレクトさせるために使用
  def logged_in_user
    unless logged_in?
      store_location
      flash[:danger] = "ログインしてください。"
      redirect_to login_url
    end
  end

  # アクセスしたユーザーが現在ログインしているユーザーか確認
  # correct_userログインしているユーザーが他のユーザーのプロフィールや情報を編集しようとした場合にリダイレクトさせるために使用
  # current_user 現在ログインしているユーザを取得するために使用
  def correct_user
    unless current_user?(@user)
      flash[:danger] = "他のユーザー情報は閲覧できません。"
      redirect_to(root_url)
    end
  end

  # システム管理権限者かどうか判定
  def admin_user
    unless current_user.admin?
      flash[:danger] = "管理者のみ閲覧可能"
      redirect_to root_url
    end
  end
  
  # 管理権限者、または現在ログインしているユーザーを許可
  def admin_or_correct_user
    @user = User.find(params[:user_id]) if @user.blank?
    unless current_user?(@user) || current_user.admin?
      flash[:danger] = "編集権限がありません。"
      redirect_to(root_url)
    end
  end
  
  # 管理者はアクセスできない。
  def not_admin
    if current_user.admin?
      flash[:danger] = "アクセス権限がありません。"
      redirect_to root_url
    end
  end

  # ページ出力前に1ヶ月分のデータの存在を確認・セットします。
  def set_one_month 
    @first_day = params[:date].nil? ?
    Date.current.beginning_of_month : params[:date].to_date
    @last_day = @first_day.end_of_month
    one_month = [*@first_day..@last_day]
  
    @attendances = @user.attendances.where(worked_on: @first_day..@last_day).order(:worked_on)
  
    unless one_month.count == @attendances.count
      ActiveRecord::Base.transaction do
        one_month.each { |day| @user.attendances.create!(worked_on: day) }
      end
      @attendances = @user.attendances.where(worked_on: @first_day..@last_day).order(:worked_on)
    end
  
  rescue ActiveRecord::RecordInvalid
    flash[:danger] = "ページ情報の取得に失敗しました、再アクセスしてください。"
    redirect_to root_url
  end
end