class BasesController < ApplicationController
  
  before_action :admin_user, only: [:index]
  def index
    @bases = Base.all
    @base = Base.new
  end

  def create
    @base = Base.new(base_params)
      if @base.save
        flash[:success] = "新規拠点情報を追加しました。"
        redirect_to bases_url
      else
        flash[:danger] = "新規拠点情報を追加できませんでした。"
        @bases = Base.all
        render :index
      end
  end

  def edit
    @base = Base.find(params[:id])
  end

  def update
    @base = Base.find(params[:id])
    if @base.update_attributes(base_params)
      flash[:success] = "拠点を修正しました。"
      redirect_to bases_url
    else
      flash[:danger] = "拠点番号、拠点名は必須項目です。"
      render :edit
    end
  end

  def destroy
    @base = Base.find(params[:id])
    @base.destroy
    flash[:success] = "#{@base.base_name}のデータを削除しました。"
    redirect_to bases_url
  end

  private

    def base_params
      params.require(:base).permit(:base_number, :base_name, :attendance_type)
    end
end
