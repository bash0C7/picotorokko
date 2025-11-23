# frozen_string_literal: true

module Picotorokko
  # StepRunner provides step-by-step execution for scenario tests.
  # Allows running steps individually with inspection between each step.
  class StepRunner
    attr_reader :steps, :completed_steps, :current_step_index

    def initialize
      @steps = []
      @completed_steps = []
      @current_step_index = 0
    end

    # Define a step with optional verification
    def step(name, verify: nil, &block)
      @steps << {
        name: name,
        block: block,
        verify: verify
      }
    end

    # Run all steps sequentially
    def run_all
      while (result = run_next)
        @completed_steps << result
      end
      @completed_steps
    end

    # Run the next pending step
    def run_next
      return nil if @current_step_index >= @steps.size

      step_def = @steps[@current_step_index]
      result = execute_step(step_def)
      @current_step_index += 1
      result
    end

    # Get pending steps (not yet executed)
    def pending_steps
      @steps[@current_step_index..]
    end

    # Get current step to execute
    def current_step
      @steps[@current_step_index]
    end

    # Reset runner to initial state
    def reset
      @current_step_index = 0
      @completed_steps = []
    end

    # Get summary of completed steps
    def summary
      passed = @completed_steps.count { |r| r[:success] }
      failed = @completed_steps.count { |r| !r[:success] }

      {
        total: @completed_steps.size,
        passed: passed,
        failed: failed
      }
    end

    private

    def execute_step(step_def)
      start_time = Time.now
      result = {
        name: step_def[:name],
        success: true,
        verified: nil,
        error: nil,
        duration: nil
      }

      begin
        step_def[:block].call
        result[:verified] = run_verification(step_def[:verify]) if step_def[:verify]
      rescue StandardError => e
        result[:success] = false
        result[:error] = e.message
      end

      result[:duration] = Time.now - start_time
      result
    end

    def run_verification(verify_proc)
      verify_proc.call
    rescue StandardError
      false
    end
  end
end
