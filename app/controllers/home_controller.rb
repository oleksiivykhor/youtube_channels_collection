class HomeController < ApplicationController
  def index
  end

  def download
    @results = adapter.results
    if @results.empty?
      flash[:notice] = 'nothing was found'

      return render :index
    end

    create_tmp_file
    send_file csv_file_path, type: 'text/csv'
  end

  private

  def adapter
    GoogleAPI::GoogleAPIAdapter.new(params[:request], params[:count].to_i)
  end

  def create_tmp_file
    FileUtils.mkdir_p dir_name
    CSV.open(csv_file_path, 'wb') do |csv|
      csv << ['Title', 'Description', 'Subscribers amount', 'Email']
      @results.each do |result|
        row = [result.title, result.description, result.subscribers_amount,
               result.email]

        csv << row
      end
    end
  end

  def csv_file_path
    time_str = DateTime.now.strftime('%m_%d_%Y_%H_%M_%S')
    @path ||= "#{dir_name}/results_#{time_str}.csv"
  end

  def dir_name
    '/tmp/youtube_channels_collection'
  end
end
