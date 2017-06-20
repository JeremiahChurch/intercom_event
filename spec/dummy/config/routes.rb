Rails.application.routes.draw do
  mount IntercomEvent::Engine => "/intercom_event"
end
