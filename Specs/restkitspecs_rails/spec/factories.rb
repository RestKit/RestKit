Factory.define(:human) do |f|
	f.name "value for name"
	f.nick_name "value for nick_name"
	f.birthday Date.today
	f.sex "male"
	f.age 1
end


Factory.define(:cat) do |f|
	f.name "value for name"
	f.nick_name "value for nick_name"
	f.birth_year 1
	f.age 1
	f.color "value for color"
	f.human_id 1
end


Factory.define(:house) do |f|
	f.street "value for street"
	f.city "value for city"
	f.state "value for state"
	f.zip "value for zip"
	f.owner_id 1
end


Factory.define(:resident) do |f|
	f.house_id 1
	f.resideable_type "value for resideable_type"
	f.resideable_id 1
end
