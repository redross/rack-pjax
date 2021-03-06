require 'nokogiri'

module Rack
  class Pjax
    include Rack::Utils

    def initialize(app)
      @app = app
    end

    def call(env)
      status, headers, body = @app.call(env)
      headers = HeaderHash.new(headers)

      if pjax?(env)
        params = Request.new(env).params
        pjax_container = params['_pjax_return'] || 'data-pjax-container'

        new_body = ""
        body.each do |b|
          parsed_body = Nokogiri::HTML.fragment(b)
          container = parsed_body.at_css("[@#{pjax_container}]")
          if container
            title = parsed_body.at("title")

            new_body << title.to_s if title
            new_body << container.inner_html
          else
            new_body << b
          end
        end

        body.close if body.respond_to?(:close)
        new_body = new_body.to_s.gsub(/\"\\\\/, "\\")
        body = [new_body]

        headers['Content-Length'] &&= bytesize(new_body).to_s
        headers['X-PJAX-URL'] = env['REQUEST_URI'] if env['REQUEST_URI']
      end
      [status, headers, body]
    end

    protected
    def pjax?(env)
      env['HTTP_X_PJAX']
    end
  end
end
