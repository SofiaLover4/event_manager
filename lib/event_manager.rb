# frozen_string_literal: true

# We are going to be using the CSV library to read through the file

require 'csv'
require 'google/apis/civicinfo_v2'
require 'erb'
require 'time'

civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
civic_info.key = 'AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw'

def clean_zipcode(zipcode)
  if zipcode.nil?
    '00000'
  elsif zipcode.length < 5
    zipcode.rjust(5, '0') # Adding on extra numbers to fill out the requirement
  elsif zipcode.length > 5
    zipcode[0..4]
  else
    zipcode # This for a perfect zipcode
  end
end

# However, this is the same thing as....
def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5, '0')[0..4]
end
# It just much cleaner

# This is also to make the code much cleaner

def legislators_by_zipcode(zip)
  civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
  civic_info.key = 'AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw'

  begin
    civic_info.representative_info_by_address(
      address: zip,
      levels: 'country',
      roles: ['legislatorUpperBody', 'legislatorLowerBody']
    ).officials
  rescue
    'You can find your representatives by visiting www.commoncause.org/take-action/find-elected-officials'
  end
end

def save_thank_you_letter(id,form_letter)
  Dir.mkdir('output') unless Dir.exist?('output')

  filename = "output/thanks_#{id}.html"

  File.open(filename, 'w') do |file|
    file.puts form_letter
  end
end

def isdigit?(character)
  digits = ['0','1','2','3','4','5','6','7','8','9']
  return true if digits.include?(character)
  false # Else return false
end

def validate_number(number)
  # First get rid of all the extra padding
  number = number.split('')
  number = number.reduce('') do |new_number, char|
    if isdigit?(char)
      new_number += char
    end
    new_number
  end

  if number.length == 10
    'You will be notified for mobile alerts'
  elsif number[0] == '1' && number.length > 10
    'You will be notified for mobile alerts'
  else
    'Sorry the number you entered was not valid'
  end
end


puts 'Event Manager Initialized!'

contents = CSV.open(
  'event_attendees.csv',
  headers: true, # I am thinking the this line removes the headers as well
  header_converters: :symbol # This will make it easier to read columns
)

template_letter = File.read('form_letter.erb')
erb_template = ERB.new template_letter
hour_frequencies = {} # This is going to be see the hours
days = {
  0 => 'Sunday',
  1 => 'Monday',
  2 => 'Tuesday',
  3 => 'Wednesday',
  4 => 'Thursday',
  5 => 'Friday',
  6 => 'Saturday'
}
day_frequencies = {}

contents.each do |row|
  id = row[0]
  name = row[:first_name]
  zipcode = clean_zipcode(row[:zipcode])
  legislators = legislators_by_zipcode(zipcode)
  phone_number_message = validate_number(row[:homephone])

  date = row[:regdate]
  format = '%m/%d/%y %H:%M'
  time_object = Time.strptime(date, format)
  hour = time_object.hour
  day = days[time_object.wday] # This will translate it into a week day
  hour_frequencies[hour] = hour_frequencies.fetch(hour, 0) + 1
  puts day
  day_frequencies[day] = day_frequencies.fetch(day, 0) + 1
  # form_letter = erb_template.result(binding)

  # save_thank_you_letter(id, form_letter)
end
highest_frequency_hour = hour_frequencies.values.max # This will return the highest value
frequent_hours = hour_frequencies.select{ |hour, frequency| frequency == highest_frequency_hour}.keys # This returns a dictionary so we just want the highest hours
highest_frequency_day = day_frequencies.values.max # Similar thing is going on for days
frequent_days = day_frequencies.select {|day, frequency| frequency == highest_frequency_day}.keys
puts "The most frequent hours are #{frequent_hours}"
puts "The most freqent days are #{frequent_days}"
