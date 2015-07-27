require "spec"

def succ(a)
  res = a + 2
  res
end

def pred(a)
  res = a - 1
  res
end

describe "self" do
  it "succ" do
    succ(1).should eq(2)
  end

  it "other" do
    pred(2).should eq(1)
  end
end
