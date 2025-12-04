# frozen_string_literal: true

# M5Stack ATOM Matrix Button Demo
# Press the center button to see "push" output

puts "ATOM Matrix Button Demo"
puts "Press button to trigger"

Button.init

loop do
  Button.update

  puts "push" if Button.was_pressed?

  sleep 0.1
end
