#!/usr/bin/env ruby
# frozen_string_literal: true

# Step Execution Example for Scenario Tests
# ===========================================================
#
# This example demonstrates how to use ruby -r debug with
# scenario tests to verify behavior interactively.
#
# Usage:
#   ruby -r debug -Itest .claude/examples/step-execution-example.rb
#
# At the debugger prompt:
#   (rdbg) step                    # Step to next line
#   (rdbg) pp tmpdir               # Print tmpdir path
#   (rdbg) pp project_id           # Print project_id
#   (rdbg) continue                # Continue to next breakpoint
#   (rdbg) quit                    # Exit debugger
#
# ===========================================================

require "tmpdir"
require "fileutils"
require "open3"

# Helper methods (copied from test_helper.rb for standalone use)
def generate_project_id
  timestamp = Time.now.strftime("%Y%m%d_%H%M%S")
  hash_suffix = rand(0x1000000).to_s(16).rjust(6, "0")
  "#{timestamp}_#{hash_suffix}"
end

def run_ptrk_command(args, cwd:)
  # Build absolute path to ptrk executable
  gem_root = File.expand_path("..", __dir__)
  ptrk_path = File.join(gem_root, "exe", "ptrk")

  stdout, stderr, status = Open3.capture3(
    "bundle exec ruby #{ptrk_path} #{args}",
    chdir: cwd
  )
  output = stdout.length.positive? ? stdout : stderr
  [output, status]
end

puts "=" * 70
puts "Step Execution Example: Scenario Test Debugging"
puts "=" * 70
puts

# Example 1: Simple Project Creation
puts "[Example 1] Simple Project Creation"
puts "-" * 70

Dir.mktmpdir do |tmpdir|
  # Generate unique project ID
  project_id = generate_project_id
  puts "tmpdir: #{tmpdir}"
  puts "project_id: #{project_id}"

  # Execute ptrk new command
  _, status = run_ptrk_command("new #{project_id}", cwd: tmpdir)

  # Check results
  puts "Command status: #{status.success? ? "\u2713 SUCCESS" : "\u2717 FAILED"}"
  puts "Exit code: #{status.exitstatus}"

  # Verify project structure
  project_dir = File.join(tmpdir, project_id)
  if Dir.exist?(project_dir)
    puts "✓ Project directory created"

    # Check key files and directories
    checks = [
      ["storage/home", :dir],
      ["mrbgems/applib", :dir],
      ["mrbgems/applib/mrblib/applib.rb", :file],
      ["README.md", :file]
    ]

    checks.each do |path, type|
      full_path = File.join(project_dir, path)
      if type == :dir
        puts "  #{Dir.exist?(full_path) ? "\u2713" : "\u2717"} #{path}/"
      else
        puts "  #{File.exist?(full_path) ? "\u2713" : "\u2717"} #{path}"
      end
    end
  else
    puts "✗ Project directory NOT created"
  end
end

puts
puts "[Example 1] Complete"
puts

# Example 2: Environment Setup
puts "[Example 2] Environment Listing"
puts "-" * 70

Dir.mktmpdir do |tmpdir|
  # Create a test project first
  project_id = generate_project_id
  _output, status = run_ptrk_command("new #{project_id}", cwd: tmpdir)

  if status.success?
    project_dir = File.join(tmpdir, project_id)
    puts "Project created at: #{project_dir}"

    # List environments (should be empty initially)
    output, status = run_ptrk_command("env list", cwd: project_dir)
    puts "env list command status: #{status.success? ? "\u2713 SUCCESS" : "\u2717 FAILED"}"
    puts "Output:"
    puts output
  else
    puts "Failed to create test project"
  end
end

puts
puts "[Example 2] Complete"
puts

# Example 3: Multi-Step Workflow
puts "[Example 3] Multi-Step Workflow"
puts "-" * 70

Dir.mktmpdir do |tmpdir|
  project_id = generate_project_id
  puts "Creating project: #{project_id}"

  # Step 1: Create project
  _, status = run_ptrk_command("new #{project_id}", cwd: tmpdir)
  puts "Step 1 - Create project: #{status.success? ? "\u2713" : "\u2717"}"

  if status.success?
    project_dir = File.join(tmpdir, project_id)

    # Step 2: Check project structure
    has_mrbgems = Dir.exist?(File.join(project_dir, "mrbgems"))
    has_storage = Dir.exist?(File.join(project_dir, "storage", "home"))
    puts "Step 2 - Verify structure:"
    puts "  mrbgems present: #{has_mrbgems ? "\u2713" : "\u2717"}"
    puts "  storage/home present: #{has_storage ? "\u2713" : "\u2717"}"

    # Step 3: Read README
    readme_path = File.join(project_dir, "README.md")
    if File.exist?(readme_path)
      content = File.read(readme_path, encoding: "UTF-8")
      has_project_name = content.include?(project_id)
      puts "Step 3 - Verify README:"
      puts "  README exists: ✓"
      puts "  Contains project name: #{has_project_name ? "\u2713" : "\u2717"}"
    else
      puts "Step 3 - Verify README: ✗ File not found"
    end
  end
end

puts
puts "[Example 3] Complete"
puts

puts "=" * 70
puts "All Examples Completed Successfully"
puts "=" * 70

# ===========================================================
# Debug Tips:
# ===========================================================
#
# When running with `ruby -r debug`, use these commands:
#
#   step    - Step into next line (enter method calls)
#   next    - Step over next line (skip method calls)
#   pp var  - Pretty-print variable
#   help    - Show all commands
#   quit    - Exit debugger
#
# Example session:
#
#   $ ruby -r debug -Itest .claude/examples/step-execution-example.rb
#   (rdbg) continue                 # Skip setup, go to main code
#   (rdbg) step                     # Enter Example 1
#   (rdbg) step                     # Create tmpdir
#   (rdbg) pp tmpdir                # Check tmpdir path
#   (rdbg) step                     # Generate project_id
#   (rdbg) pp project_id            # Check project_id
#   (rdbg) step                     # Execute ptrk command
#   (rdbg) pp output                # Check command output
#   (rdbg) pp status.success?       # Check exit status
#   (rdbg) continue                 # Jump to next section
#   (rdbg) quit                     # Exit
#
# ===========================================================
