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

  if @params[:query] && !@params[:query].empty?
    results = @database.search(@params[:query])

    page_entries = results.paginate([["_score", :desc]], :page => 1, :size => 20)
    snippet = results.expression.snippet([["<strong>", "</strong>"]], {html_escape: true, normalize: true, max_results: 10})

    r = page_entries.map do |page|
      <<EOF
  <div class="result-header"><a href="/v/#{page.book.key}#page=#{page.page_no}">#{page.book.title}</a> (P#{page.page_no})</div>
  <div class="result-sub-header"><a href="/v/#{page.book.key}?dl=1">Download</a> <a href="/v/#{page.book.key}?raw=1##{page.page_no}">Raw</a></div>
  <div class="result-body">
    #{snippet.execute(page.text).map {|segment| "<div class=\"result-body-element\">" + segment.gsub("\n", "") + "</div>"}.join("\n") }
  </div>
EOF
    end

    @content = <<EOF
<div class="matches">#{results.size} matches</div>
#{r.join("\n")}
EOF
  else
    @content = ""
  end
  
  haml :index
end

post '/search' do
  redirect "/?query=#{escape(params[:query])}"
end

get '/v/:id' do
  @database = $database

  book = @database.books[params[:id]]

  if params[:raw] == '1'
    pages = @database.book_pages(book.key)

    @content = pages.map { |page|
      <<EOF
<div id="#{page.page_no}" class="page_no">Page #{page.page_no}</div>
<pre>#{escape_html page.text}</pre>
EOF
      # <div>#{page.text}</div>
    }.join("\n")

    haml :raw
  else
    send_file(book.path, :disposition => params[:dl] == '1' ? 'download' : 'inline')
  end
end

