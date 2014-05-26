class Releaser
  def initialize(config)
  end

  def result
  end

  def run
    require 'platform-api'
    heroku = PlatformAPI.connect_oauth(config['token'])

    slug_id = heroku.release.list(config['from']).last['slug']['id']
    heroku.release.create(config['to'], slug: slug_id)
  end
end
