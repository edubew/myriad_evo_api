class Rack::Attack

  # Login by IP(5 attempts per minute)
  # Stops automated password spraying from a single IP
  throttle('login/ip', limit: 5, period: 1.minute) do |req|
    req.ip if req.path.end_with?('/login') && req.post?
  end

  # Login by email (10 attempts per hour per email address)
  # Catches distributed attacks that rotate IPs but target one account
  throttle('login/email', limit: 10, period: 1.hour) do |req|
    if req.path.end_with?('/login') && req.post?
      body = req.body.read
      req.body.rewind
      begin
        params = JSON.parse(body)
        params.dig('user', 'email')&.downcase&.strip
      rescue JSON::ParserError
        nil
      end
    end
  end

  # Registration (3 new accounts per IP per hour)
  # Prevents bulk demo/trial account abuse
  throttle('register/ip', limit: 3, period: 1.hour) do |req|
    req.ip if req.path.end_with?('/register') && req.post?
  end

  # Demo login — 5 per IP per hour
  # The demo endpoint is publicly accessible; this prevents job-queue flooding
  throttle('demo/ip', limit: 5, period: 1.hour) do |req|
    req.ip if req.path.end_with?('/demo_login') && req.post?
  end

  # Password reset — 5 per IP per hour
  throttle('password_reset/ip', limit: 5, period: 1.hour) do |req|
    req.ip if req.path.end_with?('/password') && req.post?
  end

  # General API — 300 requests per minute per authenticated user
  # Prevents a single user from hammering the API and degrading service for others
  throttle('api/user', limit: 300, period: 1.minute) do |req|
    req.env['HTTP_AUTHORIZATION']&.split(' ')&.last
  end

  # Always return JSON
  self.throttled_responder = lambda do |env|
    [
      429,
      { 'Content-Type' => 'application/json' },
      [{ success: false, error: 'Too many requests. Please try again later.' }.to_json]
    ]
  end
end
