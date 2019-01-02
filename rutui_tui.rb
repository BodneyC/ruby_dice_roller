#!/usr/bin/ruby

require 'rubygems'
require 'bundler/setup'
Bundler.require(:default)

require './client'

width = 80
height = 20

outline = RuTui::Box.new({ :x => 2, :y => 1, 
	:width => width - 2, :height => height - 2 })

############## Config Window ##############
conf_screen = RuTui::Screen.new
conf_screen.add_static outline

@conf_boxes = []
conf_screen.add_static RuTui::Text.new({ 
	:x => (width / 2) - ("Address:".length / 2), :y => (height / 2) - 6, 
	:width => width / 2, :text => "Address:" })
@conf_boxes << RuTui::Textfield.new({ 
	:x => width / 4, :y => (height / 2) - 4,
	:pixel => RuTui::Pixel.new(12, 44, "-"), :focus_pixel => RuTui::Pixel.new(15, 64, "-"),
	:width => width / 2, :text => "localhost" })

conf_screen.add_static RuTui::Text.new({ 
	:x => (width / 2) - ("Port:".length / 2), :y => (height / 2) - 2, 
	:width => width / 2, :text => "Port:" })
@conf_boxes << RuTui::Textfield.new({ 
	:x => width / 4, :y => (height / 2) + 0, 
	:pixel => RuTui::Pixel.new(12, 44, "-"), :focus_pixel => RuTui::Pixel.new(15, 64, "-"),
	:width => width / 2, :text => "8090" })

conf_screen.add_static RuTui::Text.new({ 
	:x => (width / 2) - ("Password:".length / 2), :y => (height / 2) + 2, 
	:width => width / 2, :text => "Password:" })
@conf_boxes << RuTui::Textfield.new({ 
	:x => width / 4, :y => (height / 2) + 4,
	:pixel => RuTui::Pixel.new(12, 44, "-"), :focus_pixel => RuTui::Pixel.new(15, 64, "-"),
	:width => width / 2, :text => "", :password => true })

@conf_boxes.each { |box| conf_screen.add box }

RuTui::ScreenManager.add :config, conf_screen

############## Main Screen ##############
main_screen = RuTui::Screen.new
main_screen.add_static outline

# Text box feed
@tb = []
@tb_lines = (0...height - 4)
@tb_lines.each { |i| @tb.push(RuTui::Text.new({ :x => 2, :y => i + 2, :text => "", :width => 30 })) }
# Text input field
@tf = RuTui::Textfield.new({ :x => 2, :y => height - 2, :width => width - 4, :pixel => RuTui::Pixel.new(12, 44, "-"), :focus_pixel => RuTui::Pixel.new(15, 64, "-") })

main_screen.add @tf
@tb_lines.each { |i| main_screen.add @tb[i] }

@out_text = []

RuTui::ScreenManager.add :main, main_screen

############## Running the thing ##############
def populate_textbox 
	if @out_text.size < @tb_lines.last
		for i in 0...@out_text.size do
			@tb[i].set_text @out_text[i]
		end
	else
		@tb_lines.each { |i| @tb[i].set_text @out_text[-@tb_lines.last + i] }
	end
end

leave = focus = 0

tb_thre = Thread.new do
	while RuTui::ScreenManager.get_current != :main
		sleep 0.5 
		break if leave == 1
	end
	if leave == 0
		loop do
			# Unsureity
			out_text << client_code.recv_response.split("\n")
			populate_textbox
			RuTui::ScreenManager.draw
			break if leave == 1
		end
	end
end

client_code = nil

@conf_boxes[0].set_focus
RuTui::ScreenManager.set_current :config
RuTui::ScreenManager.loop({ :autodraw => true }) do |key|
	if key == :ctrl_c
		leave = 1
		break
	end

	if RuTui::ScreenManager.get_current == :config

		if key == :down or key == :up
			if (focus == 0 and key == :down) or (focus == 2 and key == :up)
				@conf_boxes[focus].take_focus
				focus = 1
			elsif (focus == 1 and key == :down) or (focus == 0 and key == :up)
				@conf_boxes[focus].take_focus
				focus = 2
			else
				@conf_boxes[focus].take_focus
				focus = 0
			end
			@conf_boxes[focus].set_focus
			next
		end
		
		if key == :enter
			# Make constructor boolean
			# if (client_code = new Client(@conf_boxes[0], @conf_boxes[1], @conf_boxes[2])) == true
			# 	RuTui::ScreenManager.set_current :main
			# else
			# 	conf_screen.add_static RuTui::Textfield.new({ :x => (width / 2) - ("Connection Failed".length / 2), :y => (height / 2) - 8, :width => width / 2, :text => "Connection Failed" })
			# end
		end

		@conf_boxes[focus].write key

	elsif RuTui::ScreenManager.get_current == :main
		if key == :enter
			client_code.send_request @tf.text	
 			@tf.text = ""
 			@tf.create
		end
	
		@tf.write key 
	end
end

tb_thre.join

print RuTui::Ansi.clear_color + RuTui::Ansi.clear
