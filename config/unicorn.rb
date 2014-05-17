# Force the bundler gemfile environment variable to
# reference the capistrano "current" symlink
before_exec do |_|
  ENV["BUNDLE_GEMFILE"] = File.join(root, 'Gemfile')
end

if ENV["APP_ROOT"]
  working_directory = ENV['APP_ROOT']

  # Unicorn PID file location
  pid "#{ENV['APP_ROOT']}/tmp/pids/unicorn.pid"

  # Path to logs
  stderr_path "#{ENV['APP_ROOT']}/log/unicorn.log"
  stdout_path "#{ENV['APP_ROOT']}/log/unicorn.log"

  # Unicorn socket
  listen "#{ENV['APP_ROOT']}/tmp/sockets/unicorn.sock", backlog: 64
end

worker_processes Integer(ENV["WEB_CONCURRENCY"] || 3)
timeout 30
preload_app true

before_fork do |server, worker|
  Signal.trap 'TERM' do
    puts 'Unicorn master intercepting TERM and sending myself QUIT instead'
    Process.kill 'QUIT', Process.pid
  end

  defined?(ActiveRecord::Base) and
    ActiveRecord::Base.connection.disconnect!
end

after_fork do |server, worker|
  Signal.trap 'TERM' do
    puts 'Unicorn worker intercepting TERM and doing nothing. Wait for ' \
         'master to send QUIT'
  end

  defined?(ActiveRecord::Base) and
    ActiveRecord::Base.establish_connection
end
