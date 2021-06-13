# frozen_string_literal: true

require "dependabot/update_checkers"
require "dependabot/update_checkers/base"
require "dependabot/git_submodules/version"
require "dependabot/git_commit_checker"

module Dependabot
  module GitSubmodules
    class UpdateChecker < Dependabot::UpdateCheckers::Base
      def latest_version
        return latest_version_for_git_dependency
      end

      def latest_resolvable_version
        # Resolvability isn't an issue for submodules.
        latest_version
      end

      def latest_resolvable_version_with_no_unlock
        # No concept of "unlocking" for submodules
        latest_version
      end

      def updated_requirements
        # Submodule requirements are the URL and branch to use for the
        # submodule. We never want to update either.
        dependency.requirements
      end

      private

      def latest_version_resolvable_with_full_unlock?
        # Full unlock checks aren't relevant for submodules
        false
      end

      def updated_dependencies_after_full_unlock
        raise NotImplementedError
      end

      def latest_version_for_git_dependency
        # If the module isn't pinned then there's nothing for us to update
        # (since there's no lockfile to update the version in). We still
        # return the latest commit for the given branch, in order to keep
        # this method consistent
        return git_commit_checker.head_commit_for_current_branch unless git_commit_checker.pinned?

        # If the dependency is pinned to a tag that looks like a version then
        # we want to update that tag. Because we don't have a lockfile, the
        # latest version is the tag itself.
        if git_commit_checker.pinned_ref_looks_like_version?
          latest_tag = git_commit_checker.local_tag_for_latest_version&.
                       fetch(:tag)
          version_rgx = GitCommitChecker::VERSION_REGEX
          return unless latest_tag.match(version_rgx)

          version = latest_tag.match(version_rgx).
                    named_captures.fetch("version")
          return version_class.new(version)
        end

        # If the dependency is pinned to a tag that doesn't look like a
        # version then there's nothing we can do.
        nil
      end
    end
  end
end

Dependabot::UpdateCheckers.
  register("submodules", Dependabot::GitSubmodules::UpdateChecker)
