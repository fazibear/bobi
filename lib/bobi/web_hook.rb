class WebHook < Roda
  RESPONSE = "ić stąt"
  GITHUB_SECRET = ENV['BOBI_GITHUB_SECRET'] || "nothing"

  plugin :json_parser
  plugin :json

  route do |r|
    r.root { RESPONSE }
    r.post("github") { process_github(r); RESPONSE }
  end

  def process_github(r)
    params = r.params
    body = r.body.read
    computed_signature = 'sha1=' + OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new('sha1'), GITHUB_SECRET, body)
    signature = r.env['HTTP_X_HUB_SIGNATURE'] || "bad!"

    return unless Rack::Utils.secure_compare(signature, computed_signature)

    repo = params["repository"]["full_name"]
    if r.params["ref"] == "refs/heads/master"
      QUEUE.(repo)
    end
  end
end
