# Controller responsible for rendering the main single-page application view.
# Serves as the entry point for the weather application's frontend.
class HomeController < ApplicationController

  # GET /
  # Renders the main page of the single-page application
  # The actual weather interface is loaded through JavaScript
  def index
    # Main page for the single-page application renders the /app/views/home/index.html.erb view
  end
  
end
