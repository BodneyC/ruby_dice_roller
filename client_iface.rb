#!/usr/bin/ruby

require 'rubygems'
require 'bundler/setup'
Bundler.require(:default)

require './client_code'

$sc_width = 90
$sc_height = 30

outline = RuTui::Box.new({ :x => 2, :y => 1, 
	:width => $sc_width - 2, :height => $sc_height - 2 })

def make_text y, w, txt
	RuTui::Text.new({ :x => ($sc_width / 2) - (txt.length / 2), :y => y, :width => w, :text => txt})
end

def make_textfield x, y, w, txt
	RuTui::Textfield.new({ 
		:x => x, :y => y, 
		:pixel => RuTui::Pixel.new(12, 44, "-"), :focus_pixel => RuTui::Pixel.new(15, 64, "-"),
		:width => w, :text => txt })
end

################ Config Window ################
conf_screen = RuTui::Screen.new
conf_screen.add_static outline

@conf_boxes = []
conf_screen.add_static make_text(($sc_height / 2) - 8, $sc_width / 2, "Address:")
@conf_boxes << make_textfield($sc_width / 4, ($sc_height / 2) - 6, $sc_width / 2, "localhost")

conf_screen.add_static make_text(($sc_height / 2) - 4, $sc_width / 2, "Port:")
@conf_boxes << make_textfield($sc_width / 4, ($sc_height / 2) - 2, $sc_width / 2, "8090")

conf_screen.add_static make_text(($sc_height / 2) + 0, $sc_width / 2, "Username:")
@conf_boxes << make_textfield($sc_width / 4, ($sc_height / 2) + 2, $sc_width / 2, "")

conf_screen.add_static make_text(($sc_height / 2) + 4, $sc_width / 2, "Password:")
@conf_boxes << RuTui::Textfield.new({ 
	:x => $sc_width / 4, :y => ($sc_height / 2) + 6, 
	:pixel => RuTui::Pixel.new(12, 44, "-"), :focus_pixel => RuTui::Pixel.new(15, 64, "-"),
	:width => $sc_width / 2, :text => "", :password => true 
})

leave = focus = 0
@err_field = make_textfield(($sc_width / 2) - ("Connection Failed".length / 2), ($sc_height / 2) - 8, $sc_width / 2, "Connection Failed")

@conf_boxes.each { |box| conf_screen.add box }
@conf_boxes[0].set_text "localhost"
@conf_boxes[1].set_text "8090"

RuTui::ScreenManager.add :config, conf_screen

################# Main Screen #################
main_screen = RuTui::Screen.new
main_screen.add_static outline

# Text box feed
@tb = []
@tb_lines = (0...$sc_height - 6)
@tb_lines.each { |i| @tb.push(RuTui::Text.new({ :x => 4, :y => i + 2, :text => "", :width => $sc_width - 6 })) }
# Text input field
@tf = RuTui::Textfield.new({ :x => 4, :y => $sc_height - 4, :width => $sc_width - 6, :pixel => RuTui::Pixel.new(12, 44, "-"), :focus_pixel => RuTui::Pixel.new(15, 64, "-") })

main_screen.add @tf
@tb_lines.each { |i| main_screen.add @tb[i] }

RuTui::ScreenManager.add :main, main_screen

############## Running the thing ##############
marker = @tb_lines.last

def populate_textbox 
	if @out_text.size < @tb_lines.last
		for i in 0...@out_text.size do
			@tb[i].set_text @out_text[i]
		end
	else
		@tb_lines.each { |i| @tb[i].set_text @out_text[-marker + i] }
	end
end

client_code = socket = nil

@out_text = []
step = marker / 3
pswd_check = 0

# Thread used to update the screen 
tb_thr = Thread.new do
	while RuTui::ScreenManager.get_current != :main
		break if leave == 1
		sleep 0.5 
	end

	if leave == 0
		loop do
			break if leave == 1
			# Unsureity
			populate_textbox
			RuTui::ScreenManager.draw
		end
	end
end

txt_thr = Thread.new do
	while RuTui::ScreenManager.get_current != :main
		break if leave == 1
		sleep 0.5 
	end

	if leave == 0
		loop do
			break if leave == 1
			# Split by element
			tmp_txt = client_code.recv_response.to_s
			out_text << tmp_txt
		end
	end
end

@conf_boxes[0].set_focus

RuTui::ScreenManager.set_current :config
RuTui::ScreenManager.loop({ :autodraw => true }) do |key|
	if key == :ctrl_c
		leave = 1
		break
	end

	if RuTui::ScreenManager.get_current == :config
		if key == :down || key == :up
			if (focus == 0 && key == :down) || (focus == 2 && key == :up)
				@conf_boxes[focus].take_focus
				focus = 1
			elsif (focus == 1 && key == :down) || (focus == 3 && key == :up)
				@conf_boxes[focus].take_focus
				focus = 2
			elsif (focus == 2 && key == :down) || (focus == 0 && key == :up)
				@conf_boxes[focus].take_focus
				focus = 3
			else # 3 && :down || 1 && :up
				@conf_boxes[focus].take_focus
				focus = 0
			end

			@conf_boxes[focus].set_focus
			next
		end

		if key == :esc
			@conf_boxes[focus].set_text ""
			@conf_boxes[focus].create
			next
		end
		
		if key == :enter
			# Make constructor boolean
			if socket.nil?
	        	begin
					socket = TCPSocket.open(@conf_boxes[0].get_text, @conf_boxes[1].get_text)
					client_code = Client.new(socket)
	        	rescue SocketError => e
					@err_field.set_text "Incorrect addr/port"
					conf_screen.add @err_field
					socket = client_code = nil
				end
			end

			if socket
				if pswd_check == 0
					pswd_check = client_code.password(@conf_boxes[3].get_text)
				end
				if pswd_check == 1
					if client_code.username(@conf_boxes[2].get_text) == 1
						RuTui::ScreenManager.set_current :main
						@conf_boxes[focus].take_focus
						@tf.set_focus
					else
						@err_field.set_text "Incorrect Username"
						@conf_boxes[2].set_text ""
						@conf_boxes[focus].take_focus
						focus = 2
						@conf_boxes[focus].set_focus
					end
				else
					@err_field.set_text "Incorrect Password"
					@conf_boxes[3].set_text ""
					@conf_boxes[focus].take_focus
					focus = 3
					@conf_boxes[focus].set_focus
				end
			end
			next
		end

		@conf_boxes[focus].write key

	elsif RuTui::ScreenManager.get_current == :main
		if key == :down
			marker - step <= 0 ? marker = 1 : marker -= step ## May have to be <= / 1
		elsif key == :up
			marker + step > @tb_lines.last ? marker = @tb_lines.last : marker += step
		elsif key == :enter
			client_code.send_request @tf.get_text	
 			@tf.set_text ""
 			@tf.create
		else
			@tf.write key 
		end
	end
end

tb_thr.join
txt_thr.join

print RuTui::Ansi.clear_color + RuTui::Ansi.clear
