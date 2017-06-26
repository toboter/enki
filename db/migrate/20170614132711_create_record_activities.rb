class CreateRecordActivities < ActiveRecord::Migration[5.0]
  def change
    create_table :record_activities do |t|
      t.integer :actor_id
      t.references :resource, polymorphic: true, index: true
      t.string :activity_type

      t.timestamps
    end
  end
end
