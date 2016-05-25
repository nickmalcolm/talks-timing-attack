module SlowEquality
  MILLISECOND = 0.001
  MICROSECOND = 0.000001

  # Ruby's == method is too fast, and I'd have to do many more iterations
  # to accurately notice the discrepancy of it's left-evaluated approach.
  # Also it'll probably return as soon as string length is incorrect, and I don't
  # want to build for that.
  # So this is a slower, left-to-right evaluating string comparator.
  def self.str_eql?(str_a, str_b, sleep_s: 0)
    # Note down all the characters to be checked.
    chars_a = str_a.chars
    chars_b = str_b.chars

    # Go through each of str's characters, and check for equality
    while a = chars_a.shift
      b = chars_b.shift

      # I'm a slow computer, I can't check equality very fast.
      sleep sleep_s

      if a && a == b
        # Carry on, to check the next character
      else
        return false
      end
    end

    # Our method of shifting characters should result in two empty arrays
    # when the passwords have equal length.
    #
    if (chars_a.length + chars_b.length) > 0
      # Some characters were left unchecked
      false
    else
      # All chars were checked, and we must have equality.
      true
    end
  end
end