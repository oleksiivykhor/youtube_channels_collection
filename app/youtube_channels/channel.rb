module YoutubeChannels
  class Channel
    attr_reader :title,
                :description,
                :subscribers_amount,
                :email

    def initialize(search_result)
      regex = /#{URI::MailTo::EMAIL_REGEXP.source.gsub(/\\A|\\z/, '')}/
      json = JSON.parse(search_result.to_json)
      @title = json['snippet']['title']
      @description = json['snippet']['description']
      @subscribers_amount = json['statistics']['subscriberCount']
      emails = @description.scan(regex).flatten.uniq
      @email = emails.any? ? emails.join(', ') : nil
    end
  end
end
