
require 'thor'
require_relative 'version'
require_relative 'env'
require_relative 'commands/env'
require_relative 'commands/cache'
require_relative 'commands/build'
require_relative 'commands/patch'
require_relative 'commands/r2p2'
require_relative 'commands/ci'

module Pra
  # praコマンドのCLIエントリーポイント
  class CLI < Thor
    def self.exit_on_failure?
      true
    end

    # サブコマンド登録
    desc 'env SUBCOMMAND ...ARGS', 'Environment management commands'
    subcommand 'env', Pra::Commands::Env

    desc 'cache SUBCOMMAND ...ARGS', 'Cache management commands'
    subcommand 'cache', Pra::Commands::Cache

    desc 'build SUBCOMMAND ...ARGS', 'Build environment management commands'
    subcommand 'build', Pra::Commands::Build

    desc 'patch SUBCOMMAND ...ARGS', 'Patch management commands'
    subcommand 'patch', Pra::Commands::Patch

    desc 'ci SUBCOMMAND ...ARGS', 'CI/CD configuration commands'
    subcommand 'ci', Pra::Commands::Ci

    # R2P2-ESP32タスク委譲（トップレベルコマンドを動的生成）
    # Note: 'build'は除外（Build Environment Managementのサブコマンドと衝突するため）
    Pra::Commands::R2P2.tasks.each do |task_name, task|
      next if task_name.to_s == 'build'  # buildコマンドは除外

      desc "#{task_name} [ENV_NAME]", task.description
      option :env, type: :string, default: 'current', aliases: '-e', desc: 'Environment name'

      define_method(task_name) do |env_name = nil|
        env_name ||= options[:env]
        Pra::Commands::R2P2.new.send(task_name, env_name)
      end
    end

    # バージョン表示
    desc 'version', 'Show pra version'
    def version
      puts "pra version #{Pra::VERSION}"
    end
    map %w[--version -v] => :version
  end
end
