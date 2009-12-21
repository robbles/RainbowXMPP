class ColorsController < ApplicationController
  
  def index
    render
  end
  
  def create
    begin
      #TurkIM.send_message("slatewest@jannuss-macbook-pro.local", "<color> BLUE </color>")
      TurkIM.send_message("platform@macpro.local", params[:color])
      #TurkIM.change_color(params[:color].to_sym)
    rescue DRb::DRbConnError => e
      Rails.logger.info "The DRb server could not be contacted"
    end

    respond_to do |format|
      format.html { redirect_to colors_url }
    end
  end
  
end
