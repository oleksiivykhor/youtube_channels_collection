require 'google/apis/youtube_v3'
require 'googleauth/stores/file_token_store'
require 'capybara/dsl'

module GoogleAPI
  class GoogleAPIAdapter
    include Capybara::DSL

    SCOPE = Google::Apis::YoutubeV3::AUTH_YOUTUBE_READONLY
    CLIENT_SECRETS_PATH = Rails.root.join('config/client_secret.json')
    CREDENTIALS_PATH = Rails.root.join('credentials.yml')
    APPLICATION_NAME = Rails.application.class.parent_name.underscore
    REDIRECT_URI = 'http://localhost'
    USER_ID = 'default'

    def initialize(request, count)
      Capybara.current_driver = :selenium_chrome_headless
      @request = request
      @count = count
    end

    def results
      find_channels.map do |channel|
        YoutubeChannels::Channel.new channel
      end
    end

    private

    def channel_ids
      ids = []
      list = nil
      count_per_page = @count < 50 ? @count : 50
      begin
        next_page_token = list&.next_page_token || nil
        list = service.list_searches(
          'snippet',
          type: 'channel',
          q: @request,
          max_results: count_per_page,
          page_token: next_page_token)
        ids.concat(list.items.map { |item| item.id.channel_id })
        ids.uniq!
      end while ids.count < @count

      ids
    rescue Google::Apis::ClientError
      # In case with client error we just return the empty array
      []
    end

    def find_channels
      channel_ids.each_with_object([]) do |channel_id, channels|
        channels.concat service.list_channels(
          'snippet,statistics',
          id: channel_id).items
      end
    end

    def authorize
      FileUtils.mkdir_p(File.dirname(CREDENTIALS_PATH))
      client_id = Google::Auth::ClientId.from_file(CLIENT_SECRETS_PATH)
      token_store = Google::Auth::Stores::FileTokenStore.new(file: CREDENTIALS_PATH)
      authorizer = Google::Auth::UserAuthorizer.new(client_id, SCOPE, token_store)
      # When CREDENTIALS_PATH file does not exists we need to approve access and
      # get authorization code to store credentials
      credentials = authorizer.get_credentials(USER_ID)
      store_credentials(authorizer) unless credentials
      authorizer.get_credentials(USER_ID)
    end

    def store_credentials(authorizer)
      authorizer.get_and_store_credentials_from_code(
        user_id: USER_ID,
        code: authorization_code(authorizer),
        base_url: REDIRECT_URI)
    end

    def authorization_code(authorizer)
      return @authorization_code if @authorization_code

      url = authorizer.get_authorization_url(base_url: REDIRECT_URI)
      visit url
      fill_form 'identifier', google_credentials['email']
      fill_form 'password', google_credentials['password']
      find(:xpath, "//*[contains(text(), '#{google_credentials['email']}')]").click
      wait_until_loading
      find(:xpath, "//div[contains(@data-custom-id, 'allow')]").click
      wait_until_loading
      find(:xpath, "//div[contains(@id, 'approve')]").click
      wait_until_loading

      @authorization_code ||= current_url[/code=([\w\W]+?)(?:\&|$)/, 1]
    end

    def fill_form(title, value)
      fill_in title, with: value
      find(:xpath, "//div[contains(@id, '#{title}Next')]").click
      wait_until_loading
    end

    def google_credentials
      YAML.load_file(Rails.root.join('config/google_credentials.yml'))
    end

    def wait_until_loading
      path = "//div[contains(@role, 'progressbar')]"
      assert_no_selector(:xpath, path, wait: 10) if has_xpath? path
    end

    def service
      service = Google::Apis::YoutubeV3::YouTubeService.new
      service.client_options.application_name = APPLICATION_NAME
      service.authorization = authorize

      service
    end
  end
end
