module Api
  module V1
    class EventsController < BaseController
      before_action :set_event, only: [:show, :update, :destroy]

      def index
        @events = current_user.events

        if params[:start].present? && params[:end].present?
          @events = @events.where(
            start_time: params[:start]..params[:end]
          )
        end

        render json: {
          success: true,
          data: @events.map { |e| event_payload(e) }
        }
      end

      def show
        render json: { success: true, data: event_payload(@event) }
      end

      def create
        @event = current_user.events.build(
          event_params.merge(source: 'manual')
        )
        if @event.save
          render json: {
            success: true,
            data: event_payload(@event)
          }, status: :created
        else
          render json: {
            success: false,
            errors: @event.errors.full_messages
          }, status: :unprocessable_content
        end
      end

      def update
        # Prevent editing project-linked events from calendar
        if @event.source == 'project'
          return render json: {
            success: false,
            error: 'Project deadlines can only be edited from the project page'
          }, status: :forbidden
        end

        if @event.update(event_params)
          render json: { success: true, data: event_payload(@event) }
        else
          render json: {
            success: false,
            errors: @event.errors.full_messages
          }, status: :unprocessable_content
        end
      end

      def destroy
        if @event.source == 'project'
          return render json: {
            success: false,
            error: 'Project deadlines can only be removed by deleting the project'
          }, status: :forbidden
        end

        @event.destroy
        render json: { success: true, message: 'Event deleted' }
      end

      private

      def set_event
        @event = current_user.events.find(params[:id])
      rescue ActiveRecord::RecordNotFound
        render json: {
          success: false,
          error: 'Event not found'
        }, status: :not_found
      end

      def event_params
        params.require(:event).permit(
          :title, :description, :start_time,
          :end_time, :all_day, :location, :event_type
        )
      end

      def event_payload(event)
        {
          id: event.id,
          title: event.title,
          description: event.description,
          start: event.start_time,
          end: event.end_time,
          allDay: event.all_day,
          location: event.location,
          event_type: event.event_type,
          color: event.color,
          source: event.source,
          source_id: event.source_id,
          user_id: event.user_id
        }
      end
    end
  end
end