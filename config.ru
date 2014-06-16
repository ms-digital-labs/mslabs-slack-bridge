require "bundler"
Bundler.require
Dotenv.load ".env.local", ".env"

helpers do
  def httpclient
    @httpclient ||= HTTPClient.new
  end
end

post "/exceptional" do
  return "No thanks" unless params[:key] == ENV["KEY"]
  json = request.body.read

  name = JsonPath.on(json, "$..error.app.name").first
  environment = JsonPath.on(json, "$..error.environment").first
  backtrace = JsonPath.on(json, "$..error.last_occurrence.backtrace").first || []
  backtrace = backtrace.reject{|l| l.include?('vendor') }.first(8)
  trigger_url = JsonPath.on(json, "$..error.last_occurrence.url").first
  request_method = JsonPath.on(json, "$..error.last_occurrence.request_method").first
  title = JsonPath.on(json, "$..error.title").first
  url = JsonPath.on(json, "$..error.url").first

  text = %{#{environment} #{name} error: <#{url}|#{title}> – [#{request_method} #{trigger_url}]}
  text = [text, *backtrace].join("\n")

  httpclient.post(
    ENV["EXCEPTIONAL_SLACK_URL"],
    JSON.dump(text: text)
  )

  "ok"
end

run Sinatra::Application
