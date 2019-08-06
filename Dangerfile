
lib_has_changes = !git.modified_files.grep(/lib/).empty?

###
### Files to warn if changed:
###

@GL_DANGER_CI_CD_FILES = ['.travis.yml', 'Dangerfile']
@GL_DANGER_DEPENDENCY_FILES = ['Gemfile']

# determine if any of the files were modified
def didModify(files_array)
	did_modify_files = false
	files_array.each do |file_name|
		if git.modified_files.include?(file_name) || git.deleted_files.include?(file_name)
			did_modify_files = true

			config_files = git.modified_files.select { |path| path.include? file_name }

			message "This PR changes #{ github.html_link(config_files) }"
		end
	end

	return did_modify_files
end

# Checks if the 'given' string contains any string in the string_array.
def contains_string(given, string_array)
  is_present = false
  string_array.each do |file_name|
    is_present = true if given.downcase.include? file_name.downcase
  end

  is_present
end

warn('Changes to CI/CD files') if didModify(@GL_DANGER_CI_CD_FILES)
warn('Changes to dependency related files') if didModify(@GL_DANGER_DEPENDENCY_FILES)

# Sometimes it's a README fix, or something like that - which isn't relevant for
# including in a project's CHANGELOG for example
not_declared_trivial = !(github.pr_title.downcase.include? "#trivial")

# Make it more obvious that a PR is a work in progress and shouldn't be merged yet
warn("PR is classed as Work in Progress") if github.pr_title.include? "[WIP]"

###
### Auto label
###

if github.pr_title.include? "[WIP]"
	auto_label.wip=(github.pr_json["number"])
else
	auto_label.remove("WIP")
end

###
### General warnings
###

warn('Big PR, try to keep changes smaller if you can') if git.lines_of_code > 500

# Changelog entries are required for changes to library files.
no_changelog_entry = !git.modified_files.include?("CHANGELOG.md")

# Dont warn about changelog until we decide on our process.
temp_skip_changelog = true

if lib_has_changes && no_changelog_entry && not_declared_trivial && !temp_skip_changelog
	warn("Any changes to library code should be reflected in the Changelog. Please consider adding a note there and adhere to the [Changelog Guidelines](https://github.com/kevnm67/danger-pivotal_tracker/wiki/Changelog).")
end

# Warn when library files changed without test coverage.
tests_updated = !git.modified_files.grep(/spec/).empty?

if lib_has_changes && !tests_updated
	warn("Library files were updated without test coverage.  Consider updating or adding tests to cover changes.")
end

pivotal_tracker.check(project_id: "9990011")
