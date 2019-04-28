require 'rails_helper'

RSpec.describe HomeController, type: :controller do
  describe 'GET #index' do
    it 'returns http success' do
      get :index

      expect(response).to have_http_status(:success)
    end
  end

  describe 'POST #download' do
    it 'renders :index with message when results was not found' do
      post :download, params: {}

      expect(response).to render_template :index
      expect(flash[:notice]).to match(/nothing was found/)
    end

    it 'downloads csv file with results' do
      expect(subject).to receive(:send_file).and_call_original
      post :download, params: { request: 'games', count: '1' }

      expect(File).to exist subject.send(:csv_file_path)
    end
  end
end
