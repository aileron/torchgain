class HomeController < ApplicationController
  def index
    render inertia: "Home", props: {
      message: "Welcome"
    }
  end
end
