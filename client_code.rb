#!/usr/bin/ruby

require 'socket'

class Client
    def initialize(socket)
        @socket = socket
        @username = ""
        @password = ""
    end

    def password password
        @password = password
        @socket.puts password
        return socket.gets.chomp.to_i
    end

    def username username
        @username = username
        @socket.puts username
        return socket.gets.chomp.to_i
    end

    def send_request message
        begin
            @socket.puts message
        rescue IOError => e
            puts "Error: #{e.message}"
        end
    end

    def recv_response
        begin
            resp = @socket.gets.chomp
        rescue IOError => e
            puts "Error: #{e.message}"
            @socket.close()
        end
        return resp
    end
end

if __FILE__ == $0
    sock_addr, sock_port, pswd = "localhost", 8090, ""

    show_help = "Usage\n\t./client.rb [<address> <port> [<password>]]"

    if ARGV.include?("-h")|| ARGV.include?("--help")
        puts "#{show_help}"
        return
    end

    sock_addr, sock_port = ARGV[0], ARGV[1] if ARGV.length >= 2
    pswd = ARGV[2] if ARGV == 3

    Client.new(sock_addr, sock_port, pswd)

end