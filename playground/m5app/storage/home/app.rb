# frozen_string_literal: true

# M5Stack ATOM Matrix Button Demo
# Using M5Unified API
# Press the center button to see "push" output

puts "M5Unified Button Demo"
puts "Press button to trigger"

M5.begin

loop do
  M5.update

  puts "push" if M5.BtnA.wasPressed?

  sleep 0.1
end
