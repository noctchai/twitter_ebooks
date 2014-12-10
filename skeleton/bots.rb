require 'twitter_ebooks'

# This is an example bot definition with event handlers commented out
# You can define and instantiate as many bots as you like

class MyBot < Ebooks::Bot
  # Configuration here applies to all MyBots
  def configure
    # Consumer details come from registering an app at https://dev.twitter.com/
    # Once you have consumer details, use "ebooks auth" for new access tokens
    self.consumer_key = '' # Your app consumer key
    self.consumer_secret = '' # Your app consumer secret

    # Users to block instead of interacting with
    self.blacklist = ['tnietzschequote']

    # Range in seconds to randomize delay when bot.delay is called
    self.delay_range = 1..6
  end

  def on_startup
    scheduler.every '24h' do
      # Tweet something every 24 hours
      # See https://github.com/jmettraux/rufus-scheduler
      # tweet("hi")
      # pic_tweet("hey", ["cuteselfie.jpg", "http://supercute.com/kitties.png"])
    end
  end

  def on_message(dm)
    # Reply to a DM
    # reply(dm, "secret secrets")
  end

  def on_follow(user)
    # Follow a user back
    # follow(user.screen_name)
    #
    # Generate a picture for whoever just followed you (provide only a file extension)
    # pic_tweet("@#{user.screen_name} Made you this.", ['.jpg']) do |filename|
    #   picture = File.new(filename)
    #   YourOwnLibrary::generate_picture(picture)
    #   picture.close
    # end
  end

  def on_mention(tweet)
    # Reply to a mention
    # reply(tweet, meta(tweet).reply_prefix + "oh hullo")
    #
    # Edit a picture tweeted at you
    # pic_reply?("'sup", meta(tweet).media_uris) do |filename|
    #   picture = File.new(filename)
    #   YourOwnLibrary::add_sunglasses(picture)
    #   picture.close
    # end
  end

  def on_timeline(tweet)
    # Reply to a tweet in the bot's timeline
    # reply(tweet, meta(tweet).reply_prefix + "nice tweet")
  end
end

# Make a MyBot and attach it to an account
MyBot.new("{{BOT_NAME}}") do |bot|
  bot.access_token = "" # Token connecting the app to this account
  bot.access_token_secret = "" # Secret connecting the app to this account
end
