# README

Retrieve the current Weather for a given address in the United States.

Things you may want to cover:

* Ruby version: ruby 3.0.0p0 (2020-12-25 revision 95aff21468) [x86_64-
* Rails version: 6.1.7.8

* System dependencies

* Configuration

* Database creation

* Database initialization

* How to run the test suite

* Services (job queues, cache servers, search engines, etc.)

* Deployment instructions

* ...

RubyMine terminal steps
Add get route config/routes.rb
  get "/articles", to: "articles#index"
bin/rails generate controller Articles index --skip-routes
bin/rails generate model Article title:string body:text
bin/rails db:migrate
irb> article = Article.create!(title: "Hello Rails", body: "I am on Rails!")

Weather api
https://weather.visualcrossing.com/VisualCrossingWebServices/rest/services/timeline/spring%20hill%2C%20fl?unitGroup=metric&key=YOUR_API_KEY&contentType=json

Gems:
https://logger.rocketjob.io/
https://logger.rocketjob.io/rails.html