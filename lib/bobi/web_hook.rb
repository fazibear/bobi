class WebHook
  def call(env)
    req = Rack::Request.new(env)
    if req.post?
      json = parse(req.body.read)
      LOGGER.info(json)
      repo = json["repository"]["full_name"]

      if json["ref"] == "refs/heads/master"
        POOL.post do
          BUILDER.build(repo)
        rescue => e
          LOGGER.error(e)
        end
      end
    end
    [200, {"Content-Type" => "text/plain; charset=utf8"}, ["ić stąt!"]]
  end

  def parse(json)
    JSON.parse(json)
  rescue
    {}
  end
end
