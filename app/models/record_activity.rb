class RecordActivity < ApplicationRecord
  belongs_to :actor, class_name: 'User'
  belongs_to :resource, polymorphic: true

  validates :resource, :actor, :activity_type, presence: true

  def self.activity_types
    %w(Created Published)
  end

end

  # belongs_to :record_creator, class_name: 'User'
  # belongs_to :record_publisher, class_name: 'User'


  #   @subject.record_creator = current_user


  # <li id="share_record_creator" class="list-group-item">
  #   <%= fa_icon('file') %> Created by
  #   <strong><%= obj.record_activity.creator.name %></strong>
  # </li>

  #   <%= content_tag :li, id: "share_record_publisher", class: "list-group-item" do %>
  #     <%= fa_icon('file') %> Published by
  #     <strong><%= obj.record_activity.publisher.name %></strong>
  #   <% end if obj.record_publisher %>
  
  # <%= simple_form_for obj, remote: true do |f| %>
  #   <%= f.input :record_publisher, input_html: { value: current_user } %>
  #   <%= f.submit %>
  # <% end %>