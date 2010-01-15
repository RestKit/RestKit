module ControllerSpecHelper
  
  def enable_ssl
    request.env['HTTPS'] = 'on'
  end
  
  def disable_ssl
    request.env['HTTPS'] = 'off'
  end
  
  def with_ssl
    old_https = @request.env['HTTPS']
    begin
      request.env['HTTPS'] = 'on'
      yield
    ensure
      request.env['HTTPS'] = old_https
    end
  end
  
end

