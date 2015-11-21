# Jsoning

Turning object into json can sometimes be frustrating. With Jsoning, you could turn your
everyday ruby object into JSON, very easily. It should work with
any Ruby object there is. Kiss good bye to complexity

[![Code Climate](https://codeclimate.com/github/saveav/jsoning/badges/gpa.svg)](https://codeclimate.com/github/saveav/jsoning)
[ ![Codeship Status for saveav/bali](https://codeship.com/projects/b58d3950-493b-0133-a217-168d58eb1296/status?branch=release)](https://codeship.com/projects/105558)

Please refer to the test spec for better understanding. Thank you.

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
3. Versioning the JSON/Hash result

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
  # demonstrating value post-processor
  key :upcase_name, from: :name, value: { |name| name.upcase }
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
{"name":"Adam Baihaqi","upcase_name":"ADAM BAIHAQI","years_old":21,"gender":"male","books":[{"name":"Quiet: The Power of Introvert"},{"name":"Harry Potter and the Half-Blood Prince"}],"degree_detail":null}
```

We can also pretty-print the value, which usually is bit slower though, by calling:

```ruby
Jsoning(user, pretty: true)
```

Which will return:

```json
{
  "name": "Adam Baihaqi",
  "upcase_name": "ADAM BAIHAQI",
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
  "upcase_name": "ADAM BAIHAQI",
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

It is also possible to retrieve in form of Ruby hash rather than JSON string:

```ruby
Jsoning[user]
```

The syntax above will return ruby hash object:

```ruby
{"name"=>"Adam Baihaqi", 
 "upcase_name"=>"ADAM BAIHAQI",
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

## Parsing JSON back to Hash

The `JSON` library that is part of Ruby Standard Library already support parsing from JSON string to Hash.
However, if you feel that you need to assign default value, for example, when a value is missing, or when you want to 
enforce the schema, Ruby's own `JSON` library cannot do that yet. Jsoning, on the other hand, can.

The schema must have been defined by using `Jsoning.for` as have been demonstrated earlier.

Until then, to convert from JSON string to Hash, one can call:

```ruby
Jsoning.parse(the_json_string, Class)
```

For example, given:

```ruby
Jsoning.for(My::User) do
  key :name, null: false
  key :years_old, from: :age
  key :gender, default: "male"
  key :books, default: proc {
    default_college_books = []
    default_college_books << My::Book.new("Mathematics 6A")
    default_college_books << My::Book.new("Physics A2")
    default_college_books
  }
  key :degree_detail, from: :taken_degree
end

the_json_string = %Q{
  {"name":"Adam Baihaqi",
   "upcase_name"=>"ADAM BAIHAQI",
   "years_old":21,
   "gender":"male",
   "books":[{"name":"Mathematics 6A"},{"name":"Physics A2"}],
   "degree_detail":null,
   "registered_at":"2015-11-01T14:41:09+00:00"}
} 
```

Calling: `Jsoning.parse(the_json_string, My::User)` will yield a Hash as follow:

```ruby
{"name"=>"Adam Baihaqi", 
 "upcase_name"=>"ADAM BAIHAQI",
 "years_old"=>21, 
 "gender"=>"male", 
 "books"=>[{"name"=>"Mathematics 6A"}, {"name"=>"Physics A2"}], 
 "degree_detail"=>nil, 
 "registered_at"=>"2015-11-01T14:41:09+00:00"}
```

## Versioning

Since beginning, JSONing is made to easy serializing/deserializing data from API call.
Often, API call itself can be versioned. Therefore, it would be better if JSONing
also support versioning, which it does!

By default, though, all schema are under default version. Version will be altered when
specifically modified by `version` modifier.

Suppose we have our `My::Book` to be versioned:

```ruby
Jsoning.for(My::Book) do
  version :v1 do
    key :name
  end
  version :v2 do
    key :book_name, from: :name
  end
end
```

At this point, ignoring that we have ever defined `My::Book` before, `My::Book` will have
2 Jsoning versions. If we take into account the fact that we have defined `My::Book` previously,
then, we will have one additional version: the default version.

Spec below will pass:

```ruby
book = My::Book.new("Harry Potter")
expect(Jsoning.generate(book, hash: true, version: :v1)).to eq({"name"=>"Harry Potter"})
expect(Jsoning.generate(book, hash: true, version: :v2)).to eq({"book_name"=>"Harry Potter"})
```

We can also generate the whole user json/hash, too:

```ruby
json = Jsoning.generate(user, version: :v1)
expect(JSON.parse(json)).to eq({"name"=>"Adam Baihaqi", "upcase_name"=>"ADAM BAIHAQI", "years_old"=>21, "gender"=>"male", "books"=>[{"name"=>"Quiet: The Power of Introvert"}, {"name"=>"Harry Potter and the Half-Blood Prince"}], "degree_detail"=>nil, "registered_at"=>"2015-11-01T14:41:09+0000"})
json = Jsoning.generate(user, version: :v2)
expect(JSON.parse(json)).to eq({"name"=>"Adam Baihaqi", "upcase_name"=>"ADAM BAIHAQI", "years_old"=>21, "gender"=>"male", "books"=>[{"book_name"=>"Quiet: The Power of Introvert"}, {"book_name"=>"Harry Potter and the Half-Blood Prince"}], "degree_detail"=>nil, "registered_at"=>"2015-11-01T14:41:09+0000"})
```

If for when generating object, the requested versioning is undefined, the default version will be used.

## Changelog

== Version 0.1.0

1. Ability to turn object into JSON

== Version 0.2.0

1. Ability to turn object into a hash

== Version 0.3.0

1. Allow user to specify how Jsoning would extract value from a custom data type
2. Date, DateTime, Time, ActiveSupport::TimeWithZone now is by default parsed to ISO8601 format.

== Version 0.4.0

1. When passing a proc as default value, it will be executed to assign default value when value is nil.
2. Parsing JSON string as hash by using `Jsoning.parse`

== Version 0.5.0

1. Bugfix: when Jsoning to Hash, if encountering data-like datatype, error is 
   raised due to Jsoning does not know how to extract value from them. However, if the object
   is converted to JSON string, everything is working as expected.

== Version 0.6.0

1. Versioning the way JSON/Hash is de-serialized/serialized

== Version 0.7.0

1. Add value post-processor

## License

The gem is proudly available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
