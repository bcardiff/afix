require "spec"

def succ(a)
  res = a
  a
end

describe "self" do
  it "works" do
    succ(1).should eq(2)
  end
end
