module Api
  module V1
    class AllocationSettingsController < BaseController

      def show
        setting = current_user.allocation_setting ||
          current_user.build_allocation_setting
        render json: {
          success: true,
          data: setting_payload(setting)
        }
      end

      def update
        setting = current_user.allocation_setting ||
          current_user.build_allocation_setting

        if setting.update(setting_params)
          render json: {
            success: true,
            data: setting_payload(setting)
          }
        else
          render json: {
            success: false,
            errors: setting.errors.full_messages
          }, status: :unprocessable_content
        end
      end

      private

      def setting_params
        params.require(:allocation_setting).permit(
          :salary_pct, :ops_pct, :profit_pct
        )
      end

      def setting_payload(setting)
        {
          salary_pct: setting.salary_pct || 40.0,
          ops_pct: setting.ops_pct    || 25.0,
          profit_pct: setting.profit_pct || 35.0
        }
      end
    end
  end
end