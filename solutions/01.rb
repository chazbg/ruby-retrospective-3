class Integer
  def prime?
    2.upto(abs - 1).all? { |a| abs.remainder(a).nonzero? }
	end

  def prime_factors
    arr = []
    temp = abs
    2.upto(abs).each do |a| while temp.remainder(a) == 0
        arr << a
        temp /= a
      end
    end
    arr
  end

  def harmonic
    sum = Rational(0)
    1.upto(self).each { |a| sum += Rational(1, a) }
    sum
  end

  def digits
    arr = []
    temp = self
    begin
      arr << temp.remainder(10)
      temp /= 10
    end while temp != 0
    arr.reverse
  end
end

class Array
  def frequencies
    h = Hash.new()
    each do |a|
      if nil == h[a] then h[a] = 1 else h[a] += 1 end
    end
    h
  end

  def average
    result = 0
    each { |a| result += a }
    result / Float(length)
  end

  def drop_every(n)
    newArray = []
    0.upto(length - 1).each do |i|
      if (i + 1).remainder(n) != 0 then newArray << self[i] end
    end
    newArray
  end

  def combine_with(other)
    newArray = []
    for i in 0..[length, other.length].max
      if nil != self[i] then newArray << self[i] end
      if nil != other[i] then newArray << other[i] end
    end
    newArray
  end
end