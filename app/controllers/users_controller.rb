class UsersController < ApplicationController
  before_action :set_user, only: [:show, :edit, :update, :destroy, :edit_basic_info, :update_basic_info, :show_confirmation, :list_of_commuting_employees]
  before_action :set_superior, only: [:show, :show_confirmation]
  before_action :logged_in_user, only: [:show, :index, :edit, :update, :destroy, :edit_basic_info, :update_basic_info]
  before_action :correct_user, only: [:edit, :update, :show]
  before_action :admin_user, only: [:index, :destroy, :edit_basic_info, :update_basic_info, :list_of_commuting_employees]
  before_action :set_one_month, only: [:show, :show_confirmation]
  before_action :not_admin, only: [:show]
  
  def index
    @users = User.paginate(page: params[:page])
    # @users = @users.where('name like ?', "%#{params[:search]}%") if params[:search].present?
  end

  # before_actionでまとめられないものがある。
  def show
    # @first_dayから@last_dayまでの範囲をworked_onの範囲として指定して、その範囲内の勤怠記録を検索
    # @first_dayと@last_dayはそれぞれ、選択された月の最初の日と最終の日を指すように設定
    @first_day = params[:date].nil? ? Date.today.beginning_of_month : Date.parse(params[:date])
    @last_day = @first_day.end_of_month
    # @user.idを持つユーザーのAttendanceレコードをworked_onの日付が@first_dayから@last_dayの範囲内にあるものだけを検索
    @attendances = Attendance.where(user_id: @user.id, worked_on: @first_day..@last_day)

    # idを指定すればid(1,2,3),nameを指定すれば名前を表示させる
    # @overtime_sum @user.id→@user.nameに変更
    # @attendances_sum @user.id→@user.nameに変更
    # @manager_sum @user.id→@user.nameに変更
    @worked_sum = @attendances.where.not(started_at: nil).count
    @overtime_sum = Attendance.where(overtime_request_superior: @user.name, overtime_request_status: "申請中").count
    @attendances_sum = Attendance.where(attendances_request_superior: @user.name, attendances_approval_status: "申請中").count
    @manager_sum = Attendance.where(manager_request_superior: @user.name, manager_request_status: "申請中").count
    # csv出力
    require 'csv'
    
    respond_to do |format|
      format.html
      format.csv do |csv|
        send_attendances_csv(@attendances)
      end
    end
  end
  
  def show_confirmation
    # @overtime_sum @user.id→@user.nameに変更
    # @attendances_sum @user.id→@user.nameに変更
    # @manager_sum @user.id→@user.nameに変更
    # @user.idを持つユーザーのAttendanceレコードをworked_onの日付が@first_dayから@last_dayの範囲内にあるものだけを検索
    @attendances = Attendance.where(user_id: @user.id, worked_on: @first_day..@last_day)
    @worked_sum = @attendances.where.not(started_at: nil).count
    @overtime_sum = Attendance.where(overtime_request_superior: @user.name, overtime_request_status: "申請中").count
    @attendances_sum = Attendance.where(attendances_request_superior: @user.name, attendances_approval_status: "申請中").count
    @manager_sum = Attendance.where(manager_request_superior: @user.name, manager_request_status: "申請中").count
  end
  
  def new
    @user = User.new
  end

  def create
    @user = User.new(user_params)
    if @user.save
      log_in @user
      flash[:success] = '新規作成に成功しました。'
      redirect_to @user
    else
      render :new
    end
  end

  def edit
  end

  def update
    if @user.update_attributes(user_params)
      flash[:success] = "ユーザー情報を更新しました。"
      redirect_to @user
    else
      flash[:danger] = "#{@user.name}の情報を更新できませんでした。"
      render :edit      
    end
  end

  def destroy
    @user.destroy
    flash[:success] = "#{@user.name}のデータを削除しました。"
    redirect_to users_url
  end

  def edit_basic_info
  end

  def update_basic_info
    if @user.update_attributes(basic_info_params)
      flash[:success] = "#{@user.name}の基本情報を更新しました。"
    else
      flash[:danger] = "#{@user.name}の更新は失敗しました。<br>" + @user.errors.full_messages.join("<br>")
    end
    redirect_to users_url
  end
  
  def import
    if params[:file].blank?
      flash[:danger] = "CSVファイルが選択されていません。"
    redirect_to users_url
    else
      if User.import(params[:file])
        flash[:success] = "CSVファイルのインポートに成功しました。"
      else
        flash[:danger] = "CSVファイルのインポートに失敗しました。"
      end
      redirect_to users_url
    end
  end
  
  def list_of_commuting_employees
    @users = User.all.order("id ASC")
  end

  private

    def user_params
      params.require(:user).permit(:name, :email, :affiliation, :employee_number, :uid, :password, :password_confirmation, :basic_work_time, 
                                  :designated_work_start_time, :designated_work_end_time)
    end

    def basic_info_params
      params.require(:user).permit(:name, :email, :affiliation, :employee_number, :uid, :password, :password_confirmation, :basic_work_time, 
                                  :designated_work_start_time, :designated_work_end_time)
    end
    
    def send_attendances_csv(attendances)
      # row_sep: "\r\n"→CSVファイルにおいて行を区切る時に使用　encoding:Encoding::CP932→Windowsで使用されるShift_Jisの一種
      csv_data = CSV.generate(row_sep: "\r\n", encoding:Encoding::CP932) do |csv|
        header = %w(日付 出社時間 退社時間)
        csv << header
        
        attendances.each do |day|
          values = [
            day.worked_on.strftime("%Y年%m月%d日(#{$days_of_the_week[day.worked_on.wday]})"),
            if day.started_at.present? && (day.attendances_approval_status == "承認").present?
              l(day.started_at, format: :time)
            else
              nil
            end,
            if day.finished_at.present? && (day.attendances_approval_status == "承認").present?
              l(day.finished_at, format: :time)
            else
              nil
            end
          ]
        # csv << valueshは表の行に入る値を定義します。
          csv << values
        end
      end
      # csv出力のファイル名を定義します。
      send_data(csv_data, filename: "勤怠一覧.csv")
    end

end