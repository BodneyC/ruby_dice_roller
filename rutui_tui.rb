#!/usr/bin/ruby

require 'rubygems'
require 'bundler/setup'
Bundler.require(:default)

screen = RuTui::Screen.new
@tb = []
@tb_lines = (0...5)
@tb_lines.each { |i| @tb.push(RuTui::Text.new({ :x => 2, :y => i + 2, :text => "", :width => 30 })) }

@tf = RuTui::Textfield.new({ :x => 2, :y => @tb_lines.last + 2, :width => 30, :pixel => RuTui::Pixel.new(12,44,"-"), :focus_pixel => RuTui::Pixel.new(15,64,"-") })

screen.add @tf
@tb_lines.each { |i| screen.add @tb[i] }

@focus = 0
@tf.set_focus

@out_text = []

def populate_textbox 
	if @out_text.size < @tb_lines.last
		for i in 0...@out_text.size do
			@tb[i].set_text @out_text[i]
		end
	else
		@tb_lines.each { |i| @tb[i].set_text @out_text[-@tb_lines.last + i] }
	end
end

leave = 0

tb_thre = Thread.new do
	loop do
		populate_textbox
		RuTui::ScreenManager.draw
		break if leave == 1
	end
end

RuTui::ScreenManager.add :default, screen
RuTui::ScreenManager.loop({ :autodraw => true }) do |key|
	if key == :ctrl_c
		leave = 1
		break
	end

	if key == :enter
		@out_text << @tf.get_text
        @tf.text = ""
        @tf.create
	end
		
	@tf.write key 
end

tb_thre.join

print RuTui::Ansi.clear_color + RuTui::Ansi.clear
