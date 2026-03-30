class ChangeProjectIdNullableInDocuments < ActiveRecord::Migration[7.1]
  def change
    change_column_null :documents, :project_id, true
  end
end
