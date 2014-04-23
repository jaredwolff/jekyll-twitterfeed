require 'jekyll'
require 'rubygems'
require 'twitter'
require 'yaml'
require 'dotenv'

module Jekyll

  class TwitterFeed < Generator
  priority :highest

    def generate(site)

      if !site.config['twitterfeed']
        return
      end

      config = site.config['twitterfeed'];

      # Store the data locally so we dont hit twitters servers so much
      cache_directory = config['cache_directory'] || "_data"
      cache_filename = config['cache_filename'] || "twitterfeed.yml"
      cache_file_path = cache_directory + "/" + cache_filename

      # Set the "refresh rate" -- i.e. how often we refresh the data
      refresh_rate = config["refresh_rate"] || 60

      results = nil

      # If the directory doesn't exist lets make it
      if not Dir.exist?(cache_directory)
        Dir.mkdir(cache_directory)
      end

      # Now lets check for the cache file and how old it is
      if File.exist?(cache_file_path) and ((Time.now - File.mtime(cache_file_path))/60 < refresh_rate)
        results = YAML.parse(File.read(cache_file_path));
      else

        # Load your API Keys from the .env file
        Dotenv.load

        # Init the Twitter client
        client = Twitter::REST::Client.new do |config|
          config.consumer_key        = ENV['TWITTER_API_KEY']
          config.consumer_secret     = ENV['TWITTER_API_SECRET']
          # Not used -- only need read only access
          # config.access_token        = "YOUR_ACCESS_TOKEN"
          # config.access_token_secret = "YOUR_ACCESS_SECRET"
        end

        # Use the configuration variables as set in your config file
        options = options = {:count => config['num_tweets'], :include_rts => config['include_rts']}

        # Get the tweet objects
        output = client.user_timeline(config['username'], options)

        #Init the results array
        results = Array.new()

        # For each tweet get the full text
        for tweet in output do
          results << tweet.full_text()
        end

        #Write the tweets to local file
        File.open(cache_file_path,"w") do |f|
          f.write(results.to_yaml)
        end

      end

    end

  end
end