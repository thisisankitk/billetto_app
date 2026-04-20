class CreateEventVoteHistoriesAndAddStartsAtIndex < ActiveRecord::Migration[8.1]
  def change
    create_table :event_vote_histories do |t|
      t.references :event, null: false, foreign_key: true
      t.string :user_id, null: false
      t.string :latest_vote, null: false
      t.integer :total_votes_by_user, null: false, default: 0

      t.timestamps
    end

    add_index :event_vote_histories, [ :event_id, :user_id ], unique: true
    add_index :events, :starts_at
  end
end
