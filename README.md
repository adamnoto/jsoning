# Jsoning

Turning object into json can sometimes be frustrating. With Jsoning, you could turn your
everyday ruby object into JSON, very easily. It should work with
any Ruby object there is. Kiss good bye to complexity

[![Code Climate](https://codeclimate.com/github/saveav/jsoning/badges/gpa.svg)](https://codeclimate.com/github/saveav/jsoning)
[ ![Codeship Status for saveav/bali](https://codeship.com/projects/b58d3950-493b-0133-a217-168d58eb1296/status?branch=release)](https://codeship.com/projects/105558)

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'jsoning'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install jsoning

## What it can do?

1. Generating JSON from your object
2. Generating Hash from your object

## Assumptions

We have classes already defined as follow:

```ruby
module My; end
class My::User
  attr_accessor :name, :age, :gender
  attr_accessor :taken_degree
  attr_accessor :books

  def initialize
    self.books = []
  end
end
class My::Book
  attr_accessor :name
  def initialize(name)
    self.name = name
  end
end
class My::UserDegree
  attr_accessor :faculty
  attr_accessor :degree_name

  def to_s
    "#{degree_name} at #{faculty}"
  end
end
```

## Usage

Say, we want to serialize User. First, we have to define the serializer for `My::User`:

```ruby
Jsoning.for(My::User) do
  key :name
  key :years_old, from: :age
  key :gender, default: "male"
  key :books
  key :degree_detail, from: :taken_degree
end
```

But, as user have `books` and `taken_degree` which could be an instance of `My::Book` and `My::UserDegree`,
on which Jsoning has no clue about how to serialize... you should define serializer for them as well:

```ruby
Jsoning.for(My::Book) do
  key :name
end

Jsoning.for(My::UserDegree) do
  key :faculty
  key :degree, from: :degree_name
end
```

So, where you put those codes? Anywhere you want it just make sure it is loaded/required. You can put it inside
a file for each serializer, or a single file for all serializer. Anyway you want it.

After those serializers are defined, we can have a test. Assume we let user to have value as follow:

```ruby
user = My::User.new
user.name = "Adam Baihaqi"
user.age = 21
user.books << My::Book.new("Quiet: The Power of Introvert")
user.books << My::Book.new("Harry Potter and the Half-Blood Prince")
user
```

To serialize `user`, we only need to call:

```ruby
Jsoning(user)
```

Which will return:

```json
{"name":"Adam Baihaqi","years_old":21,"gender":"male","books":[{"name":"Quiet: The Power of Introvert"},{"name":"Harry Potter and the Half-Blood Prince"}],"degree_detail":null}
```

We can also pretty-print the value, which usually is bit slower though, by calling:

```ruby
Jsoning(user, pretty: true)
```

Which will return:

```json
{
  "name": "Adam Baihaqi",
  "years_old": 21,
  "gender": "male",
  "books": [
    {
      "name": "Quiet: The Power of Introvert"
    },
    {
      "name": "Harry Potter and the Half-Blood Prince"
    }
  ],
  "degree_detail": null
}
```

Now, let us fill in the degree detail:

```ruby
degree = My::UserDegree.new
degree.faculty = "School of IT"
degree.degree_name = "B.Sc. (Hons) Computer Science"
user.taken_degree = degree
```

Jsoning the user with pretty set to true, will return:

```json
{
  "name": "Adam Baihaqi",
  "years_old": 21,
  "gender": "male",
  "books": [
    {
      "name": "Quiet: The Power of Introvert"
    },
    {
      "name": "Harry Potter and the Half-Blood Prince"
    }
  ],
  "degree_detail": {
    "faculty": "School of IT",
    "degree": "B.Sc. (Hons) Computer Science"
  }
}
```

## Returning Hash

It is also possible to return hash as well:

```ruby
Jsoning[user]
```

The syntax above will return ruby hash object:

```ruby
{"name"=>"Adam Baihaqi", 
 "years_old"=>21, 
 "gender"=>"male", 
 "books"=>[{"name"=>"Quiet: The Power of Introvert"}, {"name"=>"Harry Potter and the Half-Blood Prince"}], 
 "degree_detail"=>{"faculty"=>"School of IT", "degree"=>"B.Sc. (Hons) Computer Science"}}
```

## Supporting custom data type

JSON, by default support data type such as boolean, nil, string, and number. If you have class like
`MyFancyString` and would tell Jsoning how to interpret and extract value from them, use this syntax:

```ruby
Jsoning.add_type MyFancyString, processor: { |fancy_string| fancy_string.get_string } 
```

Internally, it is how Jsoning convert date-like data type (`Date`, `DateTime`, `Time`, `ActiveSupport::TimeWithZone`) to
ISO8601 which can be parsed by compliant JavaScript interpreter in the browser (or somewhere else).

## Changelog

== Version 0.1.0

1. Ability to turn object into JSON

== Version 0.2.0

1. Ability to turn object into a hash

== Version 0.3.0

1. Allow user to specify how Jsoning would extract value from a custom data type
2. Date, DateTime, Time, ActiveSupport::TimeWithZone now is by default parsed to ISO8601 format.

## License

The gem is proudly available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
