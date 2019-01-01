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

if __FILE__ == $0
    sock_addr, sock_port = "localhost", 8090

    show_help = "Usage\n\t./client.rb [<address> <port>]"

    if ARGV.include?("-h")|| ARGV.include?("--help")
        puts "#{show_help}"
        return
    end

    if ARGV.length == 2
        sock_addr, sock_port = ARGV[0], ARGV[1].to_i
    end

    begin
        puts "#{sock_addr}, #{sock_port}"
        socket = TCPSocket.open(sock_addr, sock_port)
    rescue SocketError => e
        puts "Error: #{e.message}"
        puts "#{show_help}"
        return
    end

    Client.new(socket)
end