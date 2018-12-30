#!/usr/bin/ruby

require 'socket'
require './dice_roller'

class Server
    def initialize(sock_addr = "localhost", sock_port = 8090)
        @server = TCPServer.open(sock_addr, sock_port)
        @connected_clients = Hash.new

        puts "[LOG]: Server started"

        run_loop()
    end

    def run_loop
        loop {
            client_connect = @server.accept

            Thread.start(client_connect) do |conn|
                username = ""

                while username == ""
                    username = conn.gets.chomp + "  "
                    username = username.slice(0..2).to_sym
                    if @connected_clients[username] != nil
                        puts "[LOG] Connection failed: #{username}. Info: #{conn}"
                        conn.puts "Username already exists, try again"
                        username = ""
                    end
                end

                puts "[LOG] Connection established: #{username}. Info: #{conn}"
                @connected_clients[username] = conn
                conn.puts "Connection established: #{username}. Info: #{conn}, pray for good RNG..."

                begin_rolling(username, conn)
            end
        }.join
    end

    def begin_rolling(username, conn)
        loop do
            message = conn.gets.chomp
            roll_info = roll(message)

            put_string = "#{username}:\n\t#{message}\n\t#{roll_info}"

            (@connected_clients).keys.each do |client|
                @connected_clients[client].puts "#{put_string}"
            end
        end
    end
end

Server.new()