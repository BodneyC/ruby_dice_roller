#!/usr/bin/ruby

require 'socket'

class Client
    def initialize(sock_addr = "localhost", sock_port = 8090)
        @socket = TCPSocket.open(sock_addr, sock_port)

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

Client.new()