#!/usr/bin/ruby

def validate(message)
    return 1 if message !~ /^\d+?d\d+?([+-]\d+?)*$/
    return 0
end

def roll_dice(die_num = 0, sides = 0)
    total = 0
    vals = []

    (1..die_num).each do
        vals << rand(1..sides)
        total += vals.last
    end

    return total, vals
end

def roll(message) 
    message = message.gsub(/\s+/, "")

    return "Invalid request" if validate(message) == 1

    # Split on [d+-] and keep
    args = message.split(/(?=[d+-])|(?<=[d+-])/)

    # Every other to int
    (0...args.length).step(2).each { |idx| args[idx] = args[idx].to_i }

    total, roll_vals = roll_dice(args[0], args[2])

    if args.size > 3
        (3...args.length).step(2).each do |idx|
            if args[idx] == "+"
                total += args[idx + 1]
            else # if "-"
                total -= args[idx + 1]
            end
        end
    end

    out_string = total.to_s 
    out_string += " [" + roll_vals.join(" + ") + "]" if args[0] > 1
    out_string += " (" + args.slice(3..-1).join(" ") + ")" if args.size > 3

    return out_string
end

if __FILE__ == $0
    line = ""
    ARGV.each { |arg| line += arg }
    puts roll line
end
