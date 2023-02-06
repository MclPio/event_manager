require 'csv'
require 'google/apis/civicinfo_v2'
require 'erb'
require 'time'
require 'date'

def clean_zipcode(zipcode)
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

def save_thank_you_letter(id, form_letter)
  Dir.mkdir('output') unless Dir.exist?('output')

  filename = "output/thanks_#{id}.html"

  File.open(filename, 'w') do |file|
    file.puts form_letter
  end
end

def clean_phone_number(phone)
  clean_phone = phone.tr('()', '').tr(' ', '').tr('-', '').tr('.', '')
  if clean_phone.length == 11 && clean_phone[0] == '1'
    clean_phone[1..clean_phone.length]
  elsif clean_phone.length == 10
    clean_phone
  elsif clean_phone.length < 10 || clean_phone.length > 11 ||
    (clean_phone.length == 11 && clean_phone[0] != '1')
    'N/A'
  end
end
#11/25/08 19:21

def peak_registeration(regdate)
  hour_registered = Time.strptime(regdate, "%y/%e/%m %k:%M").hour
end

def days_registered(regdate)
  day_registered = Date.strptime(regdate, "%y/%e/%m %k:%M").wday
end

puts 'Event Manager Initialized!'

contents = CSV.open(
  'event_attendees.csv',
  headers: true,
  header_converters: :symbol
)

template_letter = File.read('form_letter.erb')
erb_template = ERB.new template_letter
hours_registered_array = []
day_array = []

contents.each do |row|
  id = row[0]
  name = row[:first_name]
  zipcode = clean_zipcode(row[:zipcode])
  phone_number = clean_phone_number(row[:homephone])
  legislators = legislators_by_zipcode(zipcode)
  form_letter = erb_template.result(binding)
  #save_thank_you_letter(id, form_letter)
  reg_date = peak_registeration(row[:regdate])
  hours_registered_array.push(reg_date)
  week_day = days_registered(row[:regdate])
  day_array.push(week_day)
end

p hours_registered_array.tally.max_by(3) {|k, v| v}
p day_array.tally.max_by(3) {|k, v| v}