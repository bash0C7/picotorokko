# frozen_string_literal: true

require_relative "../test_helper"
require_relative "../../lib/picotorokko/step_runner"

module Picotorokko
  class StepRunnerTest < Test::Unit::TestCase
    def setup
      @runner = StepRunner.new
    end

  def test_define_step
    @runner.step("Create project") { "project created" }

    assert_equal 1, @runner.steps.size
    assert_equal "Create project", @runner.steps.first[:name]
  end

  def test_run_all_steps
    results = []
    @runner.step("Step 1") { results << 1; "done 1" }
    @runner.step("Step 2") { results << 2; "done 2" }

    @runner.run_all

    assert_equal [1, 2], results
    assert_equal 2, @runner.completed_steps.size
  end

  def test_run_next_step
    results = []
    @runner.step("Step 1") { results << 1 }
    @runner.step("Step 2") { results << 2 }

    result = @runner.run_next
    assert_equal 1, @runner.current_step_index
    assert_equal [1], results
    assert_equal "Step 1", result[:name]
    assert result[:success]

    result = @runner.run_next
    assert_equal 2, @runner.current_step_index
    assert_equal [1, 2], results
  end

  def test_run_next_returns_nil_when_complete
    @runner.step("Step 1") { "done" }
    @runner.run_next

    result = @runner.run_next
    assert_nil result
  end

  def test_step_failure_captures_error
    @runner.step("Failing step") { raise "Something went wrong" }

    result = @runner.run_next

    refute result[:success]
    assert_match(/Something went wrong/, result[:error])
  end

  def test_inspect_state_between_steps
    state = { count: 0 }
    @runner.step("Increment") { state[:count] += 1 }
    @runner.step("Double") { state[:count] *= 2 }

    @runner.run_next
    assert_equal 1, state[:count]

    @runner.run_next
    assert_equal 2, state[:count]
  end

  def test_step_with_verification
    @runner.step("Create file", verify: -> { File.exist?("/tmp/test_step_runner_file") }) do
      File.write("/tmp/test_step_runner_file", "test")
    end

    result = @runner.run_next

    assert result[:success]
    assert result[:verified]
  ensure
    FileUtils.rm_f("/tmp/test_step_runner_file")
  end

  def test_verification_failure
    @runner.step("Bad step", verify: -> { false }) do
      "executed"
    end

    result = @runner.run_next

    assert result[:success] # Step executed successfully
    refute result[:verified] # But verification failed
  end

  def test_reset_runner
    @runner.step("Step 1") { "done" }
    @runner.run_all

    @runner.reset

    assert_equal 0, @runner.current_step_index
    assert_empty @runner.completed_steps
  end

  def test_step_results_include_timing
    @runner.step("Timed step") { sleep 0.01; "done" }

    result = @runner.run_next

    assert result[:duration]
    assert result[:duration] >= 0.01
  end

  def test_pending_steps
    @runner.step("Step 1") { "done" }
    @runner.step("Step 2") { "done" }
    @runner.step("Step 3") { "done" }

    @runner.run_next

    assert_equal 2, @runner.pending_steps.size
    assert_equal "Step 2", @runner.pending_steps.first[:name]
  end

  def test_current_step
    @runner.step("Step 1") { "done" }
    @runner.step("Step 2") { "done" }

    assert_equal "Step 1", @runner.current_step[:name]

    @runner.run_next

    assert_equal "Step 2", @runner.current_step[:name]
  end

  def test_summary_report
    @runner.step("Good step") { "ok" }
    @runner.step("Bad step") { raise "error" }

    @runner.run_all

    summary = @runner.summary

    assert_equal 2, summary[:total]
    assert_equal 1, summary[:passed]
    assert_equal 1, summary[:failed]
  end
  end
end
