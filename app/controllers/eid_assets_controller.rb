class U5AssetsController < ApplicationController
  unloadable 
  
  def display
    unless params[:f].nil?
      file = File.open("#{File.dirname(File.dirname(__FILE__))}/assets/#{params[:f]}", "r")
          
      result = file.read()    
          
      file.close
          
      render :text => result
    else 
      render :text => ""
    end
    
  end

end 
