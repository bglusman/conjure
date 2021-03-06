describe "conjure command line" do
  it "shows usage info when no arguments are given" do
    result = run_local "conjure"
    expect(result.standard_output).to match("Commands:")
    expect(result.standard_output.lines.count).to be >= 6
    expect(result.standard_error).to eq("")
    expect(result.exit_status).to eq(0)
  end

  it "shows error when an unknown command is given" do
    result = run_local "conjure invalid_command"
    expect(result.standard_error).to match("Could not find command")
    expect(result.standard_output).to eq("")
  end

  it "allows specifying a branch to deploy with --branch" do
    result = run_local "conjure deploy --origin /myrepo.git --branch mybranch"
    expect(result.standard_output).to match("Deploying mybranch")
  end

  it "allows specifying a branch to deploy with -b" do
    result = run_local "conjure deploy --origin /myrepo.git -b mybranch"
    expect(result.standard_output).to match("Deploying mybranch")
  end

  it "defaults to deploying master if no branch given" do
    result = run_local "conjure deploy --origin /myrepo.git --test"
    expect(result.standard_output).to match("Deploying master")
  end

  require "open3"
  def run_local(text)
    result = Open3.capture3 "ruby -Ilib bin/#{text}"
    Struct.new(:standard_output, :standard_error, :exit_status).new *result
  end
end
