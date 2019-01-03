#!/usr/bin/ruby

require 'rubygems'
require 'bundler/setup'
Bundler.require(:default)

require './client_code'

width = 80
height = 20

outline = RuTui::Box.new({ :x => 2, :y => 1, 
	:width => width - 2, :height => height - 2 })

def make_text y, w, txt
	RuTui::Text.new({ :x => (width / 2) - (txt.length / 2), :y => y, :width => w, :text => txt})
end

def make_textfield x, y, w, txt
	RuTui::Textfield.new({ 
		:x => x, :y => y, 
		:pixel => bg_pixel, :focus_pixel => focus_pixel,
		:width => w, :text => txt })
end

# May all need to be Pixel.new()
bg_pixel = RuTui::Pixel.new(12, 44, "-"), focus_pixel = RuTui::Pixel.new(15, 64, "-")

################ Config Window ################
conf_screen = RuTui::Screen.new
conf_screen.add_static outline

@conf_boxes = []
conf_screen.add_static make_text((height / 2) - 7, width / 2, "Address:")
@conf_boxes << make_textfield(width / 4, (height / 2) - 5, width / 2, "localhost")

conf_screen.add_static make_text((height / 2) - 3, width / 2, "Port:")
@conf_boxes << make_textfield(width / 4, (height / 2) - 1, width / 2, "8090")

conf_screen.add_static make_text((height / 2) + 1, width / 2, "Username:")
@conf_boxes << make_textfield(width / 4, (height / 2) + 3, width / 2, "")

conf_screen.add_static make_text((height / 2) + 5, width / 2, "Password:")
@conf_boxes << RuTui.Textfield.new({ 
	:x => width / 4, :y => (height / 2) + 7, 
	:pixel => bg_pixel, :focus_pixel => focus_pixel,
	:width => width / 2, :text => "", :password => true 
})

leave = focus = 0
@err_field = make_textfield((width / 2) - ("Connection Failed".length / 2), (height / 2) - 8, width / 2, "Connection Failed")

@conf_boxes.each { |box| conf_screen.add box }

RuTui::ScreenManager.add :config, conf_screen

################# Main Screen #################
main_screen = RuTui::Screen.new
main_screen.add_static outline

# Text box feed
@tb = []
@tb_lines = (0...height - 4)
@tb_lines.each { |i| @tb.push(RuTui::Text.new({ :x => 2, :y => i + 2, :text => "", :width => 30 })) }
# Text input field
@tf = RuTui::Textfield.new({ :x => 2, :y => height - 2, :width => width - 4, :pixel => bg_pixel, :focus_pixel => focus_pixel })

main_screen.add @tf
@tb_lines.each { |i| main_screen.add @tb[i] }

RuTui::ScreenManager.add :main, main_screen

############## Running the thing ##############
def populate_textbox 
	if @out_text.size < @tb_lines.last
		for i in 0...@out_text.size do
			@tb[i].set_text @out_text[i]
		end
	else
		@tb_lines.each { |i| @tb[i].set_text @out_text[-marker + i] }
	end
end

@out_text = []
marker = @tb_lines.last
step = marker / 3

# Thread used to update the screen 
tb_thre = Thread.new do
	while RuTui::ScreenManager.get_current != :main
		break if leave == 1
		sleep 0.5 
	end

	if leave == 0
		loop do
			break if leave == 1
			# Unsureity
			out_text << client_code.recv_response.split("\n")
			populate_textbox
			RuTui::ScreenManager.draw
		end
	end

end

@conf_boxes[0].set_focus
client_code = socket = nil

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
		
		if key == :enter
			# Make constructor boolean
			if socket.nil?
	        	begin
	        	    socket = TCPSocket.open(@conf_boxes[0], @conf_boxes[1])
					client_code = new Client(socket)
	        	rescue SocketError => e
					@err_field.set_text "Incorrect addr/port"
					conf_screen.add @err_field
					socket = client_code = nil
				end
			end

			if socket 
				if client_code.password @conf_boxes[3]
					if client_code.username @conf_boxes[2]
						RuTui::ScreenManager.set_current = :main
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
		else

		@conf_boxes[focus].write key

	elsif RuTui::ScreenManager.get_current == :main
		if key == :down
			marker - step <= 0 ? marker = 1 : marker -= step ## May have to be <= / 1
		elsif key == :up
			marker + step > @tb_lines.last ? marker = @tb_lines.last : marker += step
		elsif key == :enter
			client_code.send_request @tf.text	
 			@tf.text = ""
 			@tf.create
		else
			@tf.write key 
		end
	end
end

tb_thre.join

print RuTui::Ansi.clear_color + RuTui::Ansi.clear
