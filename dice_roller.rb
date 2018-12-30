#!/usr/bin/ruby

def roll_dice(die_num = 0, sides = 0)
    total = 0
    vals = []

    (1..die_num).each do
        tmp_rand = rand(1..sides)
        total += tmp_rand
        vals << tmp_rand
    end

    return total, vals
end

line = ""
for arg in ARGV
    line += arg
end

# Validation
if line !~ /^\d+?d\d+?([+-]\d+?)*$/
    puts "Incorrect input"
    return
end

# Split on [d+-] and keep
args = line.split(/(?=[d+-])|(?<=[d+-])/)

# Every other to int
(0...args.length).step(2).each { |idx| args[idx] = args[idx].to_i }

total, roll_vals = roll_dice(args[0], args[2])

if args.size > 3
    (3...args.length).step(2).each do |idx|
        if args[idx] == "+"
            total += args[idx + 1]
        else
            total -= args[idx + 1]
        end
    end
end

out_string = total.to_s 

if args[0] > 1
    out_string += " [" + roll_vals.join(" + ") + "]"
end

if args.size > 3
    out_string += " (" + args.slice(3..-1).join(" ") + ")"
end

puts "#{out_string}"