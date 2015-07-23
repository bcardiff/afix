require "spec"

def succ(a)
  res = a + 2
  res = res + 1
  res
end

describe "self" do
  it "works" do
    succ(1).should eq(2)
  end
end
