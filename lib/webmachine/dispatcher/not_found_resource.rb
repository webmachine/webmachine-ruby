class Webmachine::Dispatcher::NotFoundResource < Webmachine::Resource
  def resource_exists?
    false
  end
end
