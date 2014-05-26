require_relative 'vendor/heroics/lib/heroics'
require_relative 'vendor/platform-api/lib/platform-api'

class Releaser < Struct.new(:config)
  def result
  end

  def run
    heroku = PlatformAPI.connect_oauth(config['token'])

    slug_id = heroku.release.list(config['from']).last['slug']['id']
    heroku.release.create(config['to'], slug: slug_id)
    nil
  end
end
