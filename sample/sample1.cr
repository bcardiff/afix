require "spec"

def succ(a)
  res = a + 2
  res
end

describe "self" do
  it "works" do
    succ(1).should eq(2)
  end
end
