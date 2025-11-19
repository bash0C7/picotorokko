require "test_helper"

class PrkTemplateYamlEngineTest < PraTestCase
  # YamlTemplateEngine の単体テスト

  test "renders YAML template with single placeholder" do
    template = create_yaml_template(<<~YAML)
      name: __PTRK_TEMPLATE_WORKFLOW_NAME__
      version: 1.0
    YAML
    result = Ptrk::Template::YamlTemplateEngine.new(template, { workflow_name: "MyWorkflow" }).render

    assert_include(result, "MyWorkflow")
    assert_not_include(result, "TEMPLATE_")
  ensure
    FileUtils.rm_f(template)
  end

  test "renders YAML template with multiple placeholders" do
    template = create_yaml_template(<<~YAML)
      name: __PTRK_TEMPLATE_WORKFLOW_NAME__
      branch: __PTRK_TEMPLATE_MAIN_BRANCH__
      version: 1.0
    YAML
    variables = { workflow_name: "BuildWorkflow", main_branch: "main" }
    result = Ptrk::Template::YamlTemplateEngine.new(template, variables).render

    assert_include(result, "BuildWorkflow")
    assert_include(result, "main")
    assert_not_include(result, "TEMPLATE_")
  ensure
    FileUtils.rm_f(template)
  end

  test "handles placeholders in nested YAML structure" do
    template = create_yaml_template(<<~YAML)
      name: MyWorkflow
      on:
        push:
          branches:
            - __PTRK_TEMPLATE_MAIN_BRANCH__
      jobs:
        build:
          runs-on: __PTRK_TEMPLATE_RUNNER__
    YAML
    variables = { main_branch: "main", runner: "ubuntu-latest" }
    result = Ptrk::Template::YamlTemplateEngine.new(template, variables).render

    assert_include(result, "main")
    assert_include(result, "ubuntu-latest")
  ensure
    FileUtils.rm_f(template)
  end

  test "preserves YAML structure with placeholder replacement" do
    template = create_yaml_template(<<~YAML)
      name: __PTRK_TEMPLATE_WORKFLOW_NAME__
      on:
        push:
          branches:
            - main
      jobs:
        test:
          runs-on: ubuntu-latest
    YAML
    result = Ptrk::Template::YamlTemplateEngine.new(template, { workflow_name: "TestFlow" }).render

    # Result should be valid YAML
    parsed = YAML.safe_load(result)
    assert_equal("TestFlow", parsed["name"])
    assert_equal("ubuntu-latest", parsed["jobs"]["test"]["runs-on"])
  ensure
    FileUtils.rm_f(template)
  end

  test "does not replace partial placeholder patterns" do
    template = create_yaml_template(<<~YAML)
      name: PTRK_TEMPLATE_PARTIAL
      description: Mentions __PTRK_TEMPLATE_WORKFLOW__ in text
    YAML
    result = Ptrk::Template::YamlTemplateEngine.new(template, { workflow: "MyFlow" }).render

    # Partial patterns should NOT be replaced
    assert_include(result, "PTRK_TEMPLATE_PARTIAL")
    assert_include(result, "Mentions __PTRK_TEMPLATE_WORKFLOW__ in text")
  ensure
    FileUtils.rm_f(template)
  end

  test "handles non-string YAML values (numbers, booleans)" do
    template = create_yaml_template(<<~YAML)
      version: 1.0
      enabled: true
      timeout: 300
    YAML
    result = Ptrk::Template::YamlTemplateEngine.new(template, {}).render

    parsed = YAML.safe_load(result)
    assert_equal(1.0, parsed["version"])
    assert_equal(true, parsed["enabled"])
    assert_equal(300, parsed["timeout"])
  ensure
    FileUtils.rm_f(template)
  end

  test "handles empty YAML template" do
    template = create_yaml_template("")
    result = Ptrk::Template::YamlTemplateEngine.new(template, {}).render

    assert_equal("---\n", result) # YAML dump of nil
  ensure
    FileUtils.rm_f(template)
  end

  test "handles YAML arrays with placeholders" do
    template = create_yaml_template(<<~YAML)
      branches:
        - __PTRK_TEMPLATE_MAIN_BRANCH__
        - __PTRK_TEMPLATE_DEVELOP_BRANCH__
    YAML
    variables = { main_branch: "main", develop_branch: "develop" }
    result = Ptrk::Template::YamlTemplateEngine.new(template, variables).render

    parsed = YAML.safe_load(result)
    assert_equal(["main", "develop"], parsed["branches"])
  ensure
    FileUtils.rm_f(template)
  end

  test "replaces multiple occurrences of same placeholder" do
    template = create_yaml_template(<<~YAML)
      primary_branch: __PTRK_TEMPLATE_BRANCH__
      backup_branch: __PTRK_TEMPLATE_BRANCH__
      current: __PTRK_TEMPLATE_BRANCH__
    YAML
    result = Ptrk::Template::YamlTemplateEngine.new(template, { branch: "main" }).render

    parsed = YAML.safe_load(result)
    assert_equal("main", parsed["primary_branch"])
    assert_equal("main", parsed["backup_branch"])
    assert_equal("main", parsed["current"])
  ensure
    FileUtils.rm_f(template)
  end

  private

  def create_yaml_template(content)
    path = File.join(Dir.tmpdir, "template_#{SecureRandom.hex(6)}.yml")
    File.write(path, content)
    path
  end
end
