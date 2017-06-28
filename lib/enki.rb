require 'enki/engine'
require 'active_support/concern'

module Enki
    extend ActiveSupport::Concern
    
    class_methods do

      def is_actable
        true
      end
    
      def accessible_by(user)
        accessors = [user]
        accessors << user.groups.to_a
        # get a reference to the join table
        sharings = ShareModel.arel_table
        # get a reference to the filtered table
        resources = self.base_class.arel_table
        # let AREL generate a complex SQL query
        where(
          ShareModel \
            .where(sharings[:resource_id].eq(resources[:id]).and(sharings[:resource_type].eq(self.base_class.name) )) \
            .where(
              accessors.flatten.map { |accessor|
                (sharings[:shared_to_id].eq(accessor.id.to_i)).and(sharings[:shared_to_type].eq(accessor.class)).to_sql
              }.join(' OR ')
            )
            .exists
        )
        # Join syntax
        # includes(:share_models).where(share_models: {id: nil})
        #   .or(includes(:share_models).where(share_models: {shared_to: accessors.flatten}))
      end

      def inaccessible
        sharings = ShareModel.arel_table
        resources = self.base_class.arel_table
        where(
          ShareModel \
            .where(sharings[:resource_id].eq(resources[:id]).and(sharings[:resource_type].eq(self.base_class.name) )) \
            .exists.not
        )
      end

      def published_records
        activities = RecordActivity.arel_table
        resources = self.base_class.arel_table
        where(
          RecordActivity \
            .where(activities[:resource_id].eq(resources[:id]) \
              .and(activities[:resource_type].eq(self.base_class.name)) \
              .and(activities[:activity_type].eq('Published')) ) \
            .exists
        )
      end

      def visible_for(user)
        if user && user.is_admin?
          where([accessible_by(user), inaccessible, published_records].map{|s| s.arel.constraints.reduce(:and) }.reduce(:or)) \
            .tap {|sc| sc.bind_values = [accessible_by(user), inaccessible, published_records].map(&:bind_values) }
        elsif user
          where([accessible_by(user), published_records].map{|s| s.arel.constraints.reduce(:and) }.reduce(:or)) \
            .tap {|sc| sc.bind_values = [accessible_by(user), published_records].map(&:bind_values) }
        else
          published_records
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
      has_many :share_models, as: :resource, class_name: 'ShareModel'
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

    def add_created_statement_and_share
      record_activities.create!(resource: self, actor: User.current, activity_type: 'Created')
      # self.share_it(User.current, User.current, true)
    end

      
end
