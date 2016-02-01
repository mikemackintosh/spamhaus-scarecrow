all: build run

build:
   bundle install --path vendor/bundle
  
run:
   bundle exec shotgun --server=thin --port=8000 app.rb
