# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake dbs.seed (or created alongside the db with dbs.setup).
#
# Exampless.
#   
#   cities = City.create([{ s.name = 'Chicago' } { s.name = 'Copenhagen' }])
#   Major.create(s.name = 'Daley' s.city = cities.first)

##
# Humans
Human.seed(:name) do |s|
  s.name = 'Blake Watters'
  s.nick_name = 'Captain Blakers'
  s.birthday = Date.parse('11/27/1982')
  s.sex = 'male'
end

Human.seed(:name) do |s|
  s.name = 'Sarah Wilke'
  s.nick_name = 'Scooty Puff'
  s.birthday = Date.parse('6/2/1981')
  s.sex = 'female'
end

Human.seed(:name) do |s|
  s.name = 'Jeremy Ellison'
  s.birthday = Date.parse('1/26/1985')
  s.sex = 'male'
end

Human.seed(:name) do |s|
  s.name = 'Erin Rasmusson'
  s.birthday = Date.parse('05/15/1987')
  s.sex = 'female'
end

##
# Cats
Cat.seed(:name) do |s|
  s.name = 'Asia'
  s.birth_year = '2003'
  s.color = 'Calico'
  s.human = Human.find_by_name('Blake Watters')
end

Cat.seed(:name) do |s|
  s.name = 'Roy Williams'
  s.nick_name = 'Reginald Royford Williams'
  s.birth_year = '2009'
  s.color = 'Grey and White'
  s.human = Human.find_by_name('Blake Watters')
end

Cat.seed(:name) do |s|
  s.name = 'Lola'
  s.birth_year = '2001'
  s.color = 'Orange'
  s.human = Human.find_by_name('Sarah Wilke')
end

Cat.seed(:name) do |s|
  s.name = 'Lucy'
  s.nick_name = 'The Monster'
  s.birth_year = '2009'
  s.color = 'White and Grey'
  s.human = Human.find_by_name('Sarah Wilke')
end

Cat.seed(:name) do |s|
  s.name = 'Starbuck'
  s.nick_name = 'Bucky Star'
  s.birth_year = '2008'
  s.color = 'Black and White'
  s.human = Human.find_by_name('Jeremy Ellison')
end

##
# Houses
House.seed(:street) do |s|
  s.street = '108 Cheswick Court'
                s.city = 'Carrboro'
                s.state = 'North Carolina'
                s.zip = 27510
                s.owner = Human.find_by_name('Blake Watters')
end

House.seed(:street) do |s|
  s.street = '300 Spring Valley'
                s.city = 'Carrboro'
                s.state = 'North Carolina'
                s.zip = 27510
                s.owner = Human.find_by_name('Jeremy Ellison')
end

##
# Residents

## 108 Cheswick Court
Resident.seed do |s|
  s.id = 1
  s.house = House.find_by_street('108 Cheswick Court')
  s.resideable = Human.find_by_name('Blake Watters')
end

Resident.seed do |s|
  s.id = 2
  s.house = House.find_by_street('108 Cheswick Court')
  s.resideable = Human.find_by_name('Sarah Wilke')
end

Resident.seed do |s|
  s.id = 3
  s.house = House.find_by_street('108 Cheswick Court')
  s.resideable = Cat.find_by_name('Asia')
end

Resident.seed do |s|
  s.id = 4
  s.house = House.find_by_street('108 Cheswick Court')
  s.resideable = Cat.find_by_name('Roy')
end

Resident.seed do |s|
  s.id = 5
  s.house = House.find_by_street('108 Cheswick Court')
  s.resideable = Cat.find_by_name('Lola')
end

Resident.seed do |s|
  s.id = 6
  s.house = House.find_by_street('108 Cheswick Court')
  s.resideable = Cat.find_by_name('Lucy')
end

## 300 Spring Valley
Resident.seed do |s|
  s.id = 7
  s.house = House.find_by_street('300 Spring Valley')
  s.resideable = Human.find_by_name('Jeremy Ellison')
end

Resident.seed do |s|
  s.id = 8
  s.house = House.find_by_street('300 Spring Valley')
  s.resideable = Human.find_by_name('Erin Rasmusson')
end

Resident.seed do |s|
  s.id = 9
  s.house = House.find_by_street('300 Spring Valley')
  s.resideable = Cat.find_by_name('Starbuck')
end
