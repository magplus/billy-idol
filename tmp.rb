  def switch_to_master
    if `git rev-parse --abbrev-ref HEAD` == 'master'
      self
    else
      Quitter.new "You must switch to master"
    end
  end

  def warn_for_schema_diff
    diff = `diff --suppress-common-lines -y <(heroku run cat db/schema.rb -r production) db/schema.rb`
    if diff == ""
      self
    else
      Quitter.new "You need to run migrations"
    end
  end

  def show_changes
  end

  def approve_changes
  end

  def enter_summary
  end

  def push_to_heroku
  end
