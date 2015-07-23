require "spec"

class A
  def succ(a)
    res = a + 2
    res
  end
end

describe "self" do
  it "works" do
    A.new.succ(1).should eq(2)
  end
end
