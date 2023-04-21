module AttendancesHelper

  def attendance_state(attendance)
    # 受け取ったAttendanceオブジェクトが当日と一致するか評価します。
    if Date.current == attendance.worked_on
      return '出社' if attendance.started_at.nil?
      return '退社' if attendance.started_at.present? && attendance.finished_at.nil?
    end
    # どれにも当てはまらなかった場合はfalseを返します。
    return false
  end

  # 出勤時間と退勤時間を受け取り、在社時間を計算して返します。
  def working_times(start, finish, next_day)
    if next_day && (start >= finish)
      format("%.2f", (((finish - start) / 60) / 60.0) + 24)
    else
      format("%.2f", (((finish - start) /60) / 60.0))
    end
  end
  
  # 時間外計算を計算して返します。
  def working_overtimes(designated_work_end_time, scheduled_end_time, next_day)
    if next_day
      format("%.2f", ((scheduled_end_time.hour - designated_work_end_time.hour) + (scheduled_end_time.min - designated_work_end_time.min) / 60.0) +24)
    else 
      format("%.2f", (scheduled_end_time.hour - designated_work_end_time.hour) + (scheduled_end_time.min - designated_work_end_time.min) / 60.0)
    end
  end
  
  #残業申請のステータス
    def overtime_status_text(status)
      case status
      when "申請中"
        "申請中"
      when "否認"
        "残業否認済"
      when "承認"
        "残業承認済"
      when "なし"
        "残業なし"
      else
      end
    end
end