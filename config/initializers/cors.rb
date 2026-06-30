Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins ENV.fetch('ALLOWED_ORIGINS', 'http://localhost:5173').split(',').map(&:strip)

    resource '*',
      headers:     :any,
      methods:     [:get, :post, :put, :patch, :delete, :options, :head],
      expose:      ['Authorization'],
      credentials: false   # false because we use Bearer tokens, not cookies
  end
end