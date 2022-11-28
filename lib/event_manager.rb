require 'date'
require 'csv'
require 'google/apis/civicinfo_v2'
require 'erb'

def clear_zipcode(zipcode)
  # if the zip code is more than five digits, truncate it to the first five digits
  # if the zip code is less than five digits, add zeros to the front until it becomes five digits
  zipcode.to_s.rjust(5, '0')[0..4]
end

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

def create_letter(id, form_letter)
  Dir.mkdir('output') unless Dir.exist?('output')
  filename = "output/thanks#{id}.html"
  File.open(filename, 'w') do |file|
    file.puts form_letter
  end
end

def clear_phone(phone)
  # If the phone number is less than 10 digits, assume that it is a bad number
  # If the phone number is 10 digits, assume that it is good
  # If the phone number is 11 digits and the first number is 1, trim the 1 and use the remaining 10 digits
  # If the phone number is 11 digits and the first number is not 1, then it is a bad number
  # If the phone number is more than 11 digits, assume that it is a bad number
  phone.gsub!(/[^\d]/, '')

  if phone.length < 10 || phone.length > 11 || (phone.length == 11 && phone[0] != 1)
    phone = 'Bad Number.'
  elsif phone.length == 11 && phone[0] == 1
    phone = phone[1..10]
  end

  phone
end

puts 'Event Manager Initialized!'

contents = CSV.open(
  'event_attendees.csv',
  headers: true,
  header_converters: :symbol
)

template_letter = File.read('form_letter.erb')
erb_template = ERB.new template_letter

contents.each do |row|
  id = row[0]
  name = row[:first_name]
  zipcode = clear_zipcode(row[:zipcode])
  phone = clear_phone(row[:homephone])
  legislators = legislators_by_zipcode(zipcode)

  form_letter = erb_template.result(binding)

  create_letter(id, form_letter)

  puts "id: #{id}, #{name} #{zipcode} #{phone}"
end

puts 'Done!'