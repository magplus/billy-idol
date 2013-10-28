require "heroku/command/base"

# Release stuff to Heroku.
#
class Heroku::Command::Release < Heroku::Command::Base
  # release
  #
  # Release.
  #
  def index
    switch_to_master
    warn_for_schema_diff
    show_changes
    approve_changes
    enter_summary
    push_to_heroku
  end

  private

  def switch_to_master
    `git rev-parse --abbref-ref HEAD` == 'master' or exit("You must switch to master")
  end

  def warn_for_schema_diff
    puts `diff --suppress-common-lines -y <(heroku run cat db/schema.rb -r production) db/schema.rb`
  end
end
