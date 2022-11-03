# frozen_string_literal: true

# name: discourse-remove-support
# about: A plugin that removes the Needs-Support tag after 14 days from all topics
# version: 1.0.1
# authors: Acacia Bengo Ssembajjwe
# url: https://github.com/heartsupport/discourse-remove-support
# required_version: 2.7.0

after_initialize do
  class ::Jobs::RemoveSupportTagJob < Jobs::Scheduled
    every 1.day

    def execute(args)
      needs_support_tag = Tag.find_or_create_by(name: "Needs-Support")
      # Query for all with last post created > 14 days && have the tag "Needs-Support"
      # remove the tag Needs-Support
      topics = Topic
        .joins(" INNER JOIN topic_tags ON topic_tags.topic_id = topics.id AND topic_tags.tag_id = #{needs_support_tag.id}")
        .where("last_posted_at < ?", (Time.now - 14.days))

      topics.each do |topic|
        topic.tags.delete needs_support_tag
      end
    end
  end
end
