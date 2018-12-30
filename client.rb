#!/usr/bin/ruby

require 'socket'

class Client
    def initialize(socket)
        @socket = socket

        @send_thread = send_request()
        @recv_thread = recv_response()

        @send_thread.join
        @recv_thread.join
    end

    def send_request
        puts "Please give username [restricted to three characters]:"
  
        begin
            Thread.new do
                loop do
                    message = $stdin.gets.chomp
                    @socket.puts message
                end
            end
        rescue IOError => e
            puts "Error: #{e.message}"
            @socket.close()
        end
    end

    def recv_response
        begin
            Thread.new do
                loop do
                    resp = @socket.gets.chomp
                    puts "#{resp}"
                end
            end
        rescue IOError => e
            puts "Error: #{e.message}"
            @socket.close()
        end
    end
end

sock_addr, sock_port = "localhost", 8090

if ARGV.include?("-h")|| ARGV.include?("--help")
    show_help()
    return
end

if ARGV.length == 2
    sock_addr, sock_port = ARGV[0], ARGV[1]
end

begin
    socket = TCPSocket.open(sock_addr, sock_port)
rescue SocketError => e
    puts "Error: #{e.message}"
    return
end

Client.new(socket)