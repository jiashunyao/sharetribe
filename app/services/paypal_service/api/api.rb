# rubocop:disable ConstantName

module PaypalService::API
  Api =
    if Rails.env.test?
      FakeApiImplementation
    else
      # ApiImplementation
      require_relative '../../../../spec/services/paypal_service/api/fake_api_implementation'
      FakeApiImplementation
    end
end
