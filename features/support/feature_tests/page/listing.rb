module FeatureTests
  module Page
    module Listing
      extend Capybara::DSL

      module_function

      def fill_in_booking_dates
        page_content.find("input[name=start_on]").click
        datepicker.first(".day:not(.disabled):not(.new)").click

        page_content.find("input[name=end_on]").click
        datepicker.find(".next").click
        datepicker.first(".day:not(.disabled):not(.old)").click

        find(".listing-title").click
      end

      def click_request
        page_content.click_button("Request")
      end

      def datepicker
        find(".datepicker")
      end

      def page_content
        find(".page-content")
      end
    end
  end
end
