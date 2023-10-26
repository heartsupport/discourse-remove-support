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
      supported_tag = Tag.find_or_create_by(name: "Supported")
      asked_user_tag = Tag.find_or_create_by(name: "Asked-User")
      # Query for all with last post created > 14 days && have the tag "Needs-Support"
      # remove the tag Needs-Support
      topics = Topic
        .joins(" INNER JOIN topic_tags ON topic_tags.topic_id = topics.id AND topic_tags.tag_id = #{needs_support_tag.id}")
        .where("last_posted_at < ?", 14.days.ago)

      topics.each do |topic|
        topic.tags.delete needs_support_tag
        topic.tags.delete asked_user_tag

        # add the supported tag
        topic.tags << supported_tag unless topic.tags.include?(supported_tag)
        topic.custom_fields["supported"] = true
        topic.save!

        # make an API call to create a supplier topic
        Net::HTTP.post_form(
          URI("https://porter.heartsupport.com/webhooks/supplier"),
          topic_id: topic.id,
          supported: true,
          username: topic.user.username,
          category_id: topic.category_id,
          closed: topic.closed,
        )
      end
    end
  end
end
