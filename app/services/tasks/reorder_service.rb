module Tasks
  class ReorderService < ApplicationService
    def initialize(project:, tasks_data:)
      @project    = project
      @tasks_data = tasks_data
    end

    def call
      return failure(['tasks must be an array']) unless @tasks_data.is_a?(Array)
      return failure(['tasks cannot be empty'])  if @tasks_data.empty?

      ActiveRecord::Base.transaction do
        @tasks_data.each_with_index do |task_data, index|
          task = @project.tasks.find(task_data[:id])

          unless Task::STATUSES.include?(task_data[:status].to_s)
            raise ActiveRecord::Rollback,
                  "Invalid status '#{task_data[:status]}' for task #{task_data[:id]}"
          end

          task.update!(
            status:   task_data[:status],
            position: index
          )
        end
      end

      success(true)

    rescue ActiveRecord::RecordNotFound
      failure(['One or more tasks not found or do not belong to this project'])
    rescue ActiveRecord::RecordInvalid => e
      failure(e.record.errors.full_messages)
    rescue ActiveRecord::Rollback => e
      failure([e.message])
    end
  end
end
