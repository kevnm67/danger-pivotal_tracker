# frozen_string_literal: true

module Danger
  # This is your plugin class. Any attributes or methods you expose here will
  # be available from within your Dangerfile.
  #
  # To be published on the Danger plugins site, you will need to have
  # the public interface documented. Danger uses [YARD](http://yardoc.org/)
  # for generating documentation from your plugin source, and you can verify
  # by running `danger plugins lint` or `bundle exec rake spec`.
  #
  # @example Check the PR for pivotal tracker story ID's and, if found, post links in the comments.
  #
  #          check(key: "Delivered", project_id: "PROJECT_ID")
  #
  # @see  kevnm67/danger-pivotal_tracker
  # @tags pivotal-tracker, pivotal
  #
  class DangerPivotalTracker < Plugin
    # Checks PR for pivotal stories and post links to the PR comments.
    #
    # @param [Array] key
    #         An array of story status's (e.g. Delivered, Finished, etc.)
    #
    # @param [String] project_id
    #         The pivotal tracker project ID.
    #
    # @param [String] emoji
    #         The emoji you want to display in the message.
    #
    # @param [Boolean] search_title
    #         Option to evaluate the PR title for matching pivotal stories.
    #
    # @param [Boolean] search_commits
    #         Option to evaluate commits for story matches.
    #
    # @param [Boolean] fail_on_warning
    #         Option to fail danger if no stories are found
    #
    # @param [Boolean] report_missing
    #         Option to report if no storues were found
    #
    # @return [void]
    #
    def check(key: "", project_id: "nil", emoji: ":link:", search_title: true, search_commits: false, fail_on_warning: false, report_missing: true)
      url = "https://www.pivotaltracker.com/n/projects/#{project_id}/stories/"

      throw Error("'key' missing - must supply an array of story ids") if key.nil?

      pivotal_stories = find_pivotal_stories(key: key, search_title: search_title, search_commits: search_commits)

      if !pivotal_stories.empty?
        story_urls = pivotal_stories.map { |issue| link(href: ensure_url_ends_with_slash(url), issue: issue) }.join(", ")
        message("#{emoji} #{story_urls}")
      elsif report_missing
        msg = "No story ID's were matched in the PR title or commit messages (e.g. [\#123])"

        if fail_on_warning
          fail(msg)
        else
          warn(msg)
        end
      end
    end

    # Attempts to find story ID's from PR metadata.
    #
    # @param key [Type] default: nil
    # @param search_title [Type] default: true
    # @param search_commits [Type] default: false
    # @return [Type] Matches story ids.
    def find_pivotal_stories(key: nil, search_title: true, search_commits: true)
      keys = key.kind_of?(Array) ? key.join(" |") : key
      story_key_regex_string = /(#{keys} )#(\d{6,})/i
      regexp = Regexp.new(/#{story_key_regex_string}/)

      matching_stories = []

      if search_title
        github.pr_title.gsub(regexp) do |match|
          matching_stories << extract_id(match).first

          puts "matches #{matching_stories}"
        end
      end

      if search_commits
        puts "git commits #{git.commits}"
        git.commits.map do |commit|
          commit.message.gsub(regexp) do |match|
            matching_stories << extract_id(match).first
          end
        end
      end

      if matching_stories.empty?
        github.pr_body.gsub(regexp) do |match|
          matching_stories << extract_id(match).first
        end
      end

      return matching_stories.uniq
    end

    private

    # Extracts all numbers from a given string.
    #
    # @param str [String] String to evaluate.
    # @return [String] Numberical string.
    def extract_id(str)
      str.to_s.scan(/\d+/)
    end

    # Adds a slash at the end of the url if needed.
    #
    # @param url [String] URL to evaluate.
    # @return [String] URL ending with a slash.
    def ensure_url_ends_with_slash(url)
      return "#{url}/" unless url.end_with?("/")

      return url
    end

    # Creates an HTML string to post to the PR comments.
    #
    # @param href [String] default: nil.
    # @param issue [String] default: nil
    # @return [String] HTML string linking to the story issue.
    def link(href: nil, issue: nil)
      return "<a href='#{href}#{issue}'>#{issue}</a>"
    end
  end
end
