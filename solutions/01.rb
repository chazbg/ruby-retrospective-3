class Integer
  def prime?
    return false if self < 2
    (2...self).all? { |a| remainder(a).nonzero? }
	end

  def prime_factors
    arr = []
    temp = abs
    (2..abs).each do |a| while temp.remainder(a) == 0
        arr << a
        temp /= a
      end
    end
    arr
  end

  def harmonic
    sum = Rational(0)
    (1..self).each { |a| sum += Rational(1, a) }
    sum
  end

  def digits
    abs.to_s.chars.map { |x| x.to_i }
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
    result / length.to_f
  end

  def drop_every(n)
    newArray = []
    (0...length).each do |i|
      if (i + 1).remainder(n) != 0 then newArray << self[i] end
    end
    newArray
  end

  def merge(other)
    mergedArray = []
    (0...other.length).each { |i| mergedArray += [self[i], other[i]] }
    mergedArray
  end

  def combine_with(other)
    shorter = [length, other.length].min
    length > shorter ? longer = self : longer = other

    combinedArray = merge other.slice(0, shorter)
    combinedArray += longer.slice(shorter, longer.length - shorter)
  end
end