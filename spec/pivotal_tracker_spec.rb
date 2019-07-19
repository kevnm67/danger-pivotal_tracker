# frozen_string_literal: true

require File.expand_path("spec_helper", __dir__)

# Run tests using ```bundle exec rake spec```

module Danger
  describe Danger::DangerPivotalTracker do
    it "should be a plugin" do
      expect(Danger::DangerPivotalTracker.new(nil)).to be_a Danger::Plugin
    end

    #
    # You should test your custom attributes and methods here
    #
    describe "with Dangerfile" do
      before do
        @dangerfile = testing_dangerfile
        @my_plugin = @dangerfile.pivotal_tracker

        allow(@my_plugin).to receive_message_chain("github.pr_title").and_return("[Delivered #167207295] [Finishes #333207295] #444444295 some great feature")

        allow(@my_plugin).to receive_message_chain("github.pr_body").and_return("[Delivered #167207295]")
      end

      describe "Finding pivotal stories" do
        it "returns expected story id matched in the PR title" do
          issues = @my_plugin.find_pivotal_stories(key: "Delivered")

          expect(issues).to eq(["167207295"])
        end

        it "returns only delivered stories" do
          issues = @my_plugin.find_pivotal_stories(key: "Delivered")

          expect(issues).to eq(["167207295"])
        end

        it "returns ids iff preceeded by status Finishes" do
          issues = @my_plugin.find_pivotal_stories(key: "Finishes")

          expect(issues).to eq(["333207295"])
        end

        it "returns 3 story ids when no key is provided" do
          issues = @my_plugin.find_pivotal_stories

          expect(issues).to eq(["167207295", "333207295", "444444295"])
        end
      end

      describe "Generating pivotal tracker story URLs" do
        it "creates a pivotal tracker link appending the story id" do
          issues = @my_plugin.check(key: "Delivered", project_id: "2371161")

          expect(issues.first).to include("https://www.pivotaltracker.com/n/projects/2371161/stories/167207295")
        end
      end
    end
  end
end
