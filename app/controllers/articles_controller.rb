class ArticlesController < ApplicationController
  def index
    @articles = Article.all
  end

  def show
    @hit_api = false # read from file during development

    @article = Article.find(params[:id])
    @uri = my_uri
    # Hash data or html string with Bad request
    @weather_data = my_weather
  end

  def new
    @article = Article.new
  end

  def create
    @article = Article.new(article_params)

    if @article.save
      redirect_to @article
    else
      render :new
    end
  end

  def edit
    @article = Article.find(params[:id])
  end

  def update
    @article = Article.find(params[:id])

    if @article.update(article_params)
      redirect_to @article
    else
      render :edit
    end
  end

  def destroy
    @article = Article.find(params[:id])
    @article.destroy

    redirect_to root_path
  end

  private

  def my_location
    "Spring Hill, FL"
  end

  def my_uri
    if @my_uri.nil?
      location = CGI.escape(my_location)
      date_begin_on = Date.current
      # date_end_on = 1.day.since(date_begin_on)
      date_end_on = date_begin_on
      api_key = "5M3PTGAJSEJM247DA4NZ4QADX"
      parms = "#{location}/#{date_begin_on}/#{date_end_on}"
      cgi = CGI.escape("#{location}/#{date_begin_on}/#{date_end_on}")
      uri = "https://weather.visualcrossing.com/VisualCrossingWebServices/rest/services/timeline/#{cgi}?key=#{api_key}"
      #@my_uri = "https://weather.visualcrossing.com/VisualCrossingWebServices/rest/services/timeline/London,UK?key=5M3PTGAJSEJM247DA4NZ4QADX"
      @my_uri = "https://weather.visualcrossing.com/VisualCrossingWebServices/rest/services/timeline/#{parms}?key=5M3PTGAJSEJM247DA4NZ4QADX"
      #@my_uri = URI.parse(uri)
    end
    @my_uri
  end

  def my_weather
    # TODO: convert curl to use Net::HTTP or some
    #  other http Gem
    # response = Net::HTTP.start(my_uri.host, my_uri.port) do |http|
    #   request = Net::HTTP::Get.new my_uri.request_uri
    #   http.request request # Net::HTTPResponse object
    # end
    json_data =
    if @hit_api
      `curl #{my_uri}`
    else
      # read from fixture to reduce api costs
      test_fixture_read
    end
    hash = JSON.parse(json_data)
    @presenter = VisualCrossing::Presenter.new(hash)
    test_fixture_write(json_data) if @hit_api
    hash
  rescue JSON::ParserError
    json_data
  end

  def fixture_location_path
    fixture_path = "test/fixtures/visual_crossing"
    parts = my_location.split(",")
    city = parts.first.downcase.gsub(" ", "_").strip
    state = parts.last.downcase.strip
    IOStreams.path(fixture_path, "#{city}-#{state}.json")
  end

  def test_fixture_read
    fixture_location_path.read
  end

  def test_fixture_write(my_json)
    fixture_location_path.writer { |io| io << my_json }
  end

  def article_params
    params.require(:article).permit(:title, :body)
  end
end
