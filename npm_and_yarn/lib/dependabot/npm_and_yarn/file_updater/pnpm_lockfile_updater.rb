# frozen_string_literal: true

require "shellwords"
require "uri"

require "dependabot/npm_and_yarn/file_updater"
require "dependabot/npm_and_yarn/file_parser"
require "dependabot/npm_and_yarn/update_checker/registry_finder"
require "dependabot/npm_and_yarn/native_helpers"
require "dependabot/shared_helpers"
require "dependabot/errors"

module Dependabot
  module NpmAndYarn
    class FileUpdater
      class PnpmLockfileUpdater
        def initialize(dependencies:, dependency_files:, credentials:)
          @dependencies = dependencies
          @dependency_files = dependency_files
          @credentials = credentials
        end

        attr_reader :updated_dependency_files

        def update_with_pnpm!
          SharedHelpers.in_a_temporary_directory do
            write_temporary_dependency_files

            SharedHelpers.with_git_configured(credentials: credentials) do
              argv = %w(pnpm update) + dependencies.map(&:name)

              stdout, stderr, process = Open3.capture3(argv.shelljoin)

              @updated_dependency_files = []
              filtered_dependency_files.each do |f|
                content = File.read(f.name)
                next if content == f.content

                updated_file = f.dup
                updated_file.content = content

                updated_dependency_files << updated_file
              end
            end
          end
        end

        private

        attr_reader :dependencies, :dependency_files, :credentials

        def write_temporary_dependency_files
          File.write(".npmrc", npmrc_content)

          filtered_dependency_files.each do |f|
            File.write(f.name, f.content)
          end
        end

        def npmrc_content
          NpmrcBuilder.new(
            credentials: credentials,
            dependency_files: dependency_files
          ).npmrc_content
        end

        def filtered_dependency_files
          @filtered_dependency_files ||= [
            pnpm_workspace_file,
            pnpmfile_file,
            *package_files,
            *lock_files
          ].compact
        end

        def package_files
          @package_files ||= dependency_files.select { |f| f.name.end_with?("package.json") }
        end

        def lock_files
          @lock_files ||= dependency_files.select { |f| f.name == "pnpm-lock.yaml" }
        end

        def pnpmfile_file
          @pnpmfile_file ||= dependency_files.find { |f| f.name == ".pnpmfile.cjs" }
        end

        def pnpm_workspace_file
          @pnpm_workspace_file ||= dependency_files.find { |f| f.name == "pnpm-workspace.yaml" }
        end

        def npmrc_file
          @npmrc_file ||= dependency_files.find { |f| f.name == ".npmrc" }
        end
      end
    end
  end
end
