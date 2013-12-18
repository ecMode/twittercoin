class TweetParser

  attr_accessor :tweet, :info, :mentions, :amounts

  BOT = "@tippercoin"

  def initialize(tweet, sender)
    @tweet = tweet
    @mentions = Extractor::Mentions.parse(@tweet)
    @amounts = Extractor::Amounts.parse(@tweet)

    @info = {
      recipient: @mentions.first,
      amount: @amounts.first,
      sender: sender
    }
  end

  def valid?
    # Check if nil or 0 are in info values
    (@info.values & [nil, 0]).empty? && !direct_tweet?
  end

  def direct_tweet?
    @mentions.first == BOT
  end

  def multiple_recipients?
    @mentions.count > 2 # actual recipient + BOT
  end

  module Extractor
    module Mentions
      extend self

      # Accept: String
      # Returns: Array or Strings, or nil
      def parse(tweet)
        usernames = tweet.scan(/(@\w+)/).flatten
        return [nil] if usernames.blank?
        return usernames
      end

    end

    module Amounts
      extend self

      ### Supported Currency Symbols:
      ### Order matters, higher means more priority
      SYMBOLS = [
        {
          name: :BTC,
          regex: /(\d?+.?\d+)\s?BTC/i,
          satoshify: Proc.new {|n| (n.to_f * SATOSHIS).to_i}
        },
        {
          name: :mBTC,
          regex: /(\d?+.?\d+)\s?mBTC/i,
          satoshify: Proc.new {|n| (n.to_f * SATOSHIS / MILLIBIT).to_i }
        },
        {
          name: :USD,
          regex: /(\d?+.?\d+)\s?USD/i,
          satoshify: Proc.new {|n| n } # get marketprice
        },
        {
          name: :dollar,
          regex: /(\d?+.?\d+)\s?dollar/i,
          satoshify: Proc.new {|n| n } # get marketprice
        },
        {
          name: :beer,
          regex: /(\d?+.?\d+)\s?beer/i,
          satoshify: Proc.new {|n| n } # get marketprice
        },
        {
          name: :internet,
          regex: /(\d?+.?\d+)\s?internet/i,
          satoshify: Proc.new {|n| n } # get marketprice
        }
      ]

      # Accept: String
      # Returns: Array of Integers, or nil
      def parse(tweet)

        # Parse all and loop until first symbol is valid
        # See order at top
        parse_all(tweet).each do |p|
          values = p.values.flatten
          return values if !values.empty?
        end

        # Return nil if nothing is found
        return [nil]
      end

      # Accept: String
      # Returns: Array of hash
      def parse_all(tweet)
        SYMBOLS.map do |sym|
          raw = tweet.scan(sym[:regex]).flatten
          {
            sym[:name] => raw.map { |r| sym[:satoshify].call(r) }
          }
        end
      end


    end
  end


end
