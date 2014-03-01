require 'haml'
require 'honyomi/database'
require 'sinatra'
require 'sinatra/reloader' if ENV['SINATRA_RELOADER']

include Honyomi

set :haml, :format => :html5

configure do
  $database = Database.new
end

get '/' do
  @database = $database

  results = @database.search("css text")
  page_entries = results.paginate([["_score", :desc]], :page => 1, :size => 20)
  snippet = GrnMini::Util::html_snippet_from_selection_results(results)

  r = page_entries.map do |page|
    <<EOF
  <div class="result-header"><a href="#">#{page.book.title}</a> (#{page.page_no} page)</div>
  <div class="result-body">
    #{snippet.execute(page.text).map {|segment| "<div class=\"result-body-element\">" + segment.gsub("\n", "") + "</div>"}.join("\n") }
  </div>
EOF
  end

  @content = <<EOF
<div class="matches">#{results.size} matches</div>
#{r.join("\n")}
EOF

  haml :index
end

post '/search' do
  redirect "/?query=#{escape(params[:query])}"
end
