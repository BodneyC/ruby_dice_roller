#!/usr/bin/ruby

require 'socket'
require './dice_roller'

class Server
    def initialize(server, password)
        @server = server
        @server_pswd = password
        @connected_clients = Hash.new

        puts "[LOG]: Server started"
        puts "[LOG]: Password is: #{@server_pswd}"
        puts "---------------------"

        run_loop()
    end

    def run_loop
        loop {
            client_connect = @server.accept

            Thread.start(client_connect) do |conn|
                until conn.gets.chomp == @server_pswd
                    conn.puts "0"
                end
                conn.puts "1"

                # Probably won't work vvv
                until @connected_clients[(username = conn.gets.chomp).to_sym] == nil && username.length > 0
                    puts "[LOG]: Connection failed: #{username}. Info: #{conn}"
                    conn.puts "0"
                end
                conn.puts "1"

                puts "[LOG]: Connection established: #{username}. Info: #{conn}"
                @connected_clients[username.to_sym] = conn
                conn.puts "Connection established: #{username}. Info: #{conn}\n    pray for good RNG...\n---------------------"

                begin_rolling(username, conn)
            end
        }.join
    end

    def begin_rolling(username, conn)
        loop do
            break if conn.nil?
            
            message = conn.gets.chomp
            roll_info = roll(message)

            if roll_info == "Invalid request\n---------------------"
                conn.puts roll_info
            else
                put_string = "#{username}:\n    #{message}\n    #{roll_info}\n---------------------"
                puts "[MSG]: Incoming\n#{put_string}"
                (@connected_clients).keys.each { |client| @connected_clients[client].puts "#{put_string}" }
            end
        end
    end
end

if __FILE__ == $0
    sock_addr, sock_port, password = "localhost", 8090, "cats"

    show_help = "Usage\n\t./server.rb [<address> <port> [<password]]"

    if ARGV.include?("-h")|| ARGV.include?("--help")
        puts "#{show_help}"
        return
    end

    sock_addr, sock_port = ARGV[0], ARGV[1] if ARGV.length >= 2
    password = ARGV[2] if ARGV == 3

    begin
        server = TCPServer.open(sock_addr, sock_port)
    rescue SocketError => e
        puts "Error: #{e.message}"
        puts "#{show_help}"
        return
    end

    Server.new(server, password)
end
