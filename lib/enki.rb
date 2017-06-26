require 'enki/engine'
require 'active_support/concern'

module Enki
    extend ActiveSupport::Concern
    
    class_methods do

      def is_actable
        true
      end

      def visible_for(user)
        if user # || published
          left_outer_joins(:shared_with).references(:share_models).where(share_models: {id: nil})
            .or(left_outer_joins(:shared_with).references(:share_models)
              .where(share_models: {shared_to_id: user.id, shared_to_type: 'User'}))
            .or(left_outer_joins(:shared_with).references(:share_models)
              .where(share_models: {shared_to_id: user.group_ids, shared_to_type: 'Group'}))
            # .or(left_outer_joins(:record_activities).where(record_activities: {activity_type: 'Created'}))
        else
          left_outer_joins(:shared_with).references(:share_models).where(share_models: {id: nil})
        end
      end

    end

    included do
      after_create :add_created_statement

      # Add some relations
      has_many :record_activities, as: :resource, class_name: 'RecordActivity', dependent: :destroy
      has_many :actors, through: :record_activities
      shareable owner: :record_creator

      has_many :access_groups, through: :shared_with, source: :shared_to, source_type: 'Group'
      has_many :access_users, through: :shared_with, source: :shared_to, source_type: 'User'
      has_many :group_accessors, through: :access_groups, source: :users
      def record_accessors
        User.find(access_users.pluck(:id) + group_accessors.pluck(:id)).uniq
      end

      # Added by shareable
      # to User:
      # has_many :shared_resources, as: :shared_from, class_name: 'ShareModel'
      # has_many :shared_with_me, as: :shared_to, class_name: 'ShareModel'
      # to Model:
      # has_many :shared_with, as: :resource, class_name: 'ShareModel'
    end

      def accessible_through?(user)
        published? || user.in?(record_accessors) || record_accessors.empty?
      end

      def published?
        record_activities.where(activity_type: 'Published').exists?
      end

      def record_publisher # record_activity.where(activity_type: 'Created').first.actor
        record_activities.where(activity_type: 'Published').order(created_at: :asc).first.try(:actor) || false
      end

      def created?
        record_activities.where(activity_type: 'Created').exists?
      end

      def record_creator # record_activity.where(activity_type: 'Created').first.actor
        record_activities.where(activity_type: 'Created').order(created_at: :asc).first.try(:actor) || false
      end

    def add_created_statement
      record_activities.create!(resource: self, actor: User.current, activity_type: 'Created')
    end

      
end
