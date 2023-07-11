# typed: true
# frozen_string_literal: true

module Dependabot
  module NpmAndYarn
    class PackageManager
      def initialize(package_json, lockfiles:)
        @package_json = package_json
        @lockfiles = lockfiles
      end

      def setup(name)
        locked_version = requested_version(name) || guessed_version(name)
        return unless locked_version

        _, process = Open3.capture2e("corepack", "prepare", "#{name}@#{locked_version}", "--activate")

        # In firewalled environments, we may not be able to download & activate
        # the locked version. In that case, let corepack choose the global
        # version from now on without trying to download or activate the locked
        # version.
        unless process.success?
          ENV["COREPACK_ENABLE_PROJECT_SPEC"] = "0"
          return
        end

        locked_version
      end

      def requested_version(name)
        locked = @package_json.fetch("packageManager", nil)
        return unless locked

        version_match = locked.match(/#{name}@(?<version>\d+.\d+.\d+)/)
        version_match&.named_captures&.fetch("version", nil)
      end

      def guessed_version(name)
        send(:"guess_#{name}_version", @lockfiles[name.to_sym])
      end

      def guess_yarn_version(yarn_lock)
        return unless yarn_lock
        return if Helpers.yarn_berry?(yarn_lock)

        "1.22.19"
      end

      def guess_pnpm_version(pnpm_lock)
        return unless pnpm_lock
        return if Helpers.pnpm8?(pnpm_lock)

        "7.33.3"
      end
    end
  end
end
