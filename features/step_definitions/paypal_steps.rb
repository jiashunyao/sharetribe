# coding: utf-8
def login_as(username, password)
  topbar = FeatureTests::Section::Topbar
  login_page = FeatureTests::Page::Login
  visit("/")
  topbar.click_login_link
  login_page.fill_and_submit(username: username, password: password)
  expect(page).to have_content("Welcome")
end

def logout_foo
  topbar = FeatureTests::Section::Topbar
  topbar.open_user_menu
  topbar.click_logout
  expect(page).to have_content("You have now been logged out of Test marketplace. See you soon!")
end

def logout_and_login_as(username, password)
  logout_foo
  login_as(username, password)
end

def connect_marketplace_paypal
  topbar = FeatureTests::Section::Topbar
  paypal_preferences = FeatureTests::Section::MarketplacePaypalPreferences
  admin_sidebar = FeatureTests::Section::AdminSidebar

  # Connect Paypal for admin
  topbar.navigate_to_admin
  admin_sidebar.click_payments_link
  paypal_preferences.connect_paypal_account

  expect(page).to have_content("PayPal account connected")

  # Save payment preferences
  paypal_preferences.set_payment_preferences("2.0", "5", "1.0")
  paypal_preferences.save_settings
  expect(page).to have_content("Payment preferences updated")
end

def connect_seller_paypal
  topbar = FeatureTests::Section::Topbar
  settings_sidebar = FeatureTests::Section::UserSettingsSidebar
  paypal_preferences = FeatureTests::Section::UserPaypalPreferences

  # Connect Paypal for seller
  topbar.open_user_menu
  topbar.click_settings
  settings_sidebar.click_payments_link
  paypal_preferences.connect_paypal_account

  expect(page).to have_content("PayPal account connected")

  # Grant commission fee
  paypal_preferences.grant_permission

  expect(page).to have_content("Hooray, everything is set up!")
end

def add_listing(title, price: "2.0")
  topbar = FeatureTests::Section::Topbar
  new_listing = FeatureTests::Page::NewListing

  topbar.click_post_a_new_listing
  new_listing.fill(title, price: price)
  new_listing.save_listing

  expect(page).to have_content("Listing created successfully.")
  expect(page).to have_content(title)
end

def dismiss_onboarding_wizard_dialog
  expect(page).to have_content("Woohoo, task completed!")
  page.click_on("I'll do it later, thanks")
end

Then("I expect transaction with PayPal test to pass") do
  navigation = FeatureTests::Navigation
  data = FeatureTests::Data
  home = FeatureTests::Page::Home
  listing = FeatureTests::Page::Listing
  listing_book = FeatureTests::Page::ListingBook
  topbar = FeatureTests::Section::Topbar

  marketplace = data.create_marketplace(payment_gateway: :paypal)
  admin = data.create_member(username: "paypal_admin", marketplace_id: marketplace[:id], admin: true)
  member = data.create_member(username: "paypal_buyer", marketplace_id: marketplace[:id], admin: false)

  navigation.navigate_in_marketplace!(ident: marketplace[:ident])

  login_as(admin[:username], admin[:password])
  connect_marketplace_paypal

  dismiss_onboarding_wizard_dialog

  connect_seller_paypal
  add_listing("Lörem ipsum")

  dismiss_onboarding_wizard_dialog

  # Member buys the listing
  logout_and_login_as(member[:username], member[:password])

  home.click_listing("Lörem ipsum")
  listing.fill_in_booking_dates
  listing.click_request

  expect(page).to have_content("Request Lörem ipsum")
  listing_book.fill_in_message("Trölölö")
  listing_book.proceed_to_payment

  expect(page).to have_content("Conversation with")
  expect(page).to have_content("Payment authorized")
  expect(page).to have_content("Lörem ipsum")
  expect(page).to have_content("Trölölö")

  # Adming accepts request
  logout_and_login_as(admin[:username], admin[:password])
  topbar.click_inbox

  expect(page).to have_content("Waiting for you to accept the request")
  page.click_link("Payment authorized")
  expect(page).to have_content("Conversation with")
  page.click_link("Accept request")
  expect(page).to have_content("Order details")
  page.click_button("Accept")
  expect(page).to have_content("Request accepted")
  expect(page).to have_content("Payment successful")

  # Member marks the payment completed
  logout_and_login_as(member[:username], member[:password])
  topbar.click_inbox

  expect(page).to have_content("Waiting for you to mark the order completed")
  page.click_link("accepted the request, received payment for")
  page.click_link("Mark completed")

  expect(page).to have_content("If your order has been fulfilled you should confirm it as done.")
  choose("Skip feedback")
  page.click_button("Continue")
  expect(page).to have_content("Offer confirmed")
  expect(page).to have_content("Feedback skipped")

  # Admin skips feedback
  logout_and_login_as(admin[:username], admin[:password])
  topbar.click_inbox

  expect(page).to have_content("Waiting for you to give feedback")
  page.click_link("marked the order as completed")
  page.click_link("Skip feedback")
  expect(page).to have_content("Feedback skipped")
end
