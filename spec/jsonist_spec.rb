require 'spec_helper'
require "date"

module My; end
class My::User
  attr_accessor :name, :age, :gender
  attr_accessor :taken_degree
  attr_accessor :books
  attr_accessor :created_at

  def initialize
    self.books = []
    self.created_at = DateTime.parse("2015-11-01T14:41:09Z")
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
class My::Achievement
  attr_accessor :achievement_name
end

describe Jsoning do
  before(:each) do
    Jsoning.clear
    Jsoning::TYPE_EXTENSIONS.clear
  end

  it 'has a version number' do
    expect(Jsoning::VERSION).not_to be nil
  end

  describe "DSL" do
    it "allow 'parallel_variable' to be specified implicitly" do
      Jsoning.for(My::User) do
        key :name
      end

      protocol = Jsoning.protocol_for(My::User)
      default_version = protocol.get_version(:default)

      expect(default_version.mapper_for(:name)).to_not be_nil
      name_mapper = default_version.mapper_for(:name)
      expect(name_mapper.name).to eq("name")
      expect(name_mapper.parallel_variable).to eq(:name)
    end

    it "can define dsl with specifying default value" do
      Jsoning.for(My::User) do
        key :name, default: "Adam Pahlevi"
      end

      protocol = Jsoning.protocol_for(My::User)
      default_version = protocol.get_version(:default)

      name_mapper = default_version.mapper_for(:name)
      expect(name_mapper.name).to eq("name")
      expect(name_mapper.default_value).to eq("Adam Pahlevi")
    end

    it "can define dsl with specifying nullable value" do
      Jsoning.for(My::User) do
        key :name, null: false
      end

      protocol = Jsoning.protocol_for(My::User)
      default_version = protocol.get_version(:default)
      name_mapper = default_version.mapper_for(:name)
      expect(name_mapper.name).to eq("name")
      expect(name_mapper.nullable?).to eq(false)
    end
  end # dsl

  describe "Generator" do
    let(:user) do
      user = My::User.new
      user.name = "Adam Baihaqi"
      user.age = 21
      user.books << My::Book.new("Quiet: The Power of Introvert")
      user.books << My::Book.new("Harry Potter and the Half-Blood Prince")
      user
    end

    let(:degree) do
      degree = My::UserDegree.new
      degree.faculty = "School of IT"
      degree.degree_name = "B.Sc. (Hons) Computer Science"
      degree
    end
    
    # define the Jsoning interpreter
    before do
      Jsoning.for(My::User) do
        key :name, null: false
        key :years_old, from: :age
        key :gender, default: "male"
        key :books, default: proc { [] }
        key :degree_detail, from: :taken_degree
        key :registered_at, from: :created_at
      end

      Jsoning.for(My::Book) do
        key :name
      end

      Jsoning.for(My::UserDegree) do
        key :faculty
        key :degree, from: :degree_name
      end # jsoning My::UserDegree
    end # before do

    context("with versioning") do
      before do
        Jsoning.for(My::Book) do
          version :v1 do
            key :name
          end
          version :v2 do
            key :book_name, from: :name
          end
        end # Jsoning with versioning
      end

      it "can versionise hash result" do
        book = My::Book.new("Harry Potter")
        expect(Jsoning.generate(book, hash: true, version: :v1)).to eq({"name"=>"Harry Potter"})
        expect(Jsoning.generate(book, hash: true, version: :v2)).to eq({"book_name"=>"Harry Potter"})
      end

      it "can parse versionised hash result" do
        book = My::Book.new("Harry Potter")
        expect(Jsoning.parse("{\"name\":\"Harry Potter\"}", My::Book, :v1)).to eq(Jsoning.generate(book, hash: true, version: :v1))
        expect(Jsoning.parse("{\"book_name\":\"Harry Potter\"}", My::Book, :v2)).to eq((Jsoning.generate(book, hash: true, version: :v2)))
      end

      it "can versionise json result" do
        book = My::Book.new("Harry Potter")
        expect(Jsoning.generate(book, version: :v1)).to eq("{\"name\":\"Harry Potter\"}")
        expect(Jsoning.generate(book, version: :v2)).to eq("{\"book_name\":\"Harry Potter\"}")
      end

      it "can generate versionised json from complex object" do
        json = Jsoning.generate(user, version: :v1)
        expect(JSON.parse(json)).to eq({"name"=>"Adam Baihaqi", "years_old"=>21, "gender"=>"male", "books"=>[{"name"=>"Quiet: The Power of Introvert"}, {"name"=>"Harry Potter and the Half-Blood Prince"}], "degree_detail"=>nil, "registered_at"=>"2015-11-01T14:41:09+0000"})
        json = Jsoning.generate(user, version: :v2)
        expect(JSON.parse(json)).to eq({"name"=>"Adam Baihaqi", "years_old"=>21, "gender"=>"male", "books"=>[{"book_name"=>"Quiet: The Power of Introvert"}, {"book_name"=>"Harry Potter and the Half-Blood Prince"}], "degree_detail"=>nil, "registered_at"=>"2015-11-01T14:41:09+0000"})
      end

      it "can generate versionised hash from complex object" do
        hash = Jsoning.generate(user, hash: true, version: :v1)
        expect(hash).to eq({"name"=>"Adam Baihaqi", "years_old"=>21, "gender"=>"male", "books"=>[{"name"=>"Quiet: The Power of Introvert"}, {"name"=>"Harry Potter and the Half-Blood Prince"}], "degree_detail"=>nil, "registered_at"=>"2015-11-01T14:41:09+0000"})
        hash = Jsoning.generate(user, hash: true, version: :v2)
        expect(hash).to eq({"name"=>"Adam Baihaqi", "years_old"=>21, "gender"=>"male", "books"=>[{"book_name"=>"Quiet: The Power of Introvert"}, {"book_name"=>"Harry Potter and the Half-Blood Prince"}], "degree_detail"=>nil, "registered_at"=>"2015-11-01T14:41:09+0000"})
      end
    end

    context("without versioning") do
      it "throws an error when generating JSON for unknown class" do
        expect do
          achievement = My::Achievement.new
          Jsoning(achievement)
        end.to raise_error(Jsoning::Error)
      end

      it "throws an error when null is given when field is not expected to receive null" do
        user.name = nil
        expect { Jsoning(user) }.to raise_error(Jsoning::Error)
      end

      it "throws an error when parsing for unknown class" do
        expect do
          achievement = My::Achievement.new
          Jsoning[achievement]
        end.to raise_error(Jsoning::Error)
      end

      it "does not throw an error when interpreting DateTime" do
        json_hash = Jsoning[user]
        json_str = Jsoning(user)

        expect(json_hash).to_not be_nil
        expect(json_str).to_not be_nil
      end

      it "can generate json" do
        json = Jsoning(user)
        expect(JSON.parse(json)).to eq({"name"=>"Adam Baihaqi", "years_old"=>21, "gender"=>"male", "books"=>[{"name"=>"Quiet: The Power of Introvert"}, {"name"=>"Harry Potter and the Half-Blood Prince"}], "degree_detail"=>nil, "registered_at"=>"2015-11-01T14:41:09+0000"})

        user.taken_degree = degree

        json = Jsoning(user)
        expected_hash = {"name"=>"Adam Baihaqi", "years_old"=>21, "gender"=>"male", "books"=>[{"name"=>"Quiet: The Power of Introvert"}, {"name"=>"Harry Potter and the Half-Blood Prince"}], "degree_detail"=>{"faculty"=>"School of IT", "degree"=>"B.Sc. (Hons) Computer Science"}, "registered_at"=>"2015-11-01T14:41:09+0000"}
        expect(JSON.parse(json)).to eq(expected_hash)
        expect(Jsoning.parse(json, My::User)).to eq(expected_hash)
      end

      context "when converting date-like datatype" do
        it "can convert datetime" do
          expect(user.created_at.class).to eq(DateTime)

          expect(Jsoning[user]).to eq({"name"=>"Adam Baihaqi", "years_old"=>21, "gender"=>"male", "books"=>[{"name"=>"Quiet: The Power of Introvert"}, {"name"=>"Harry Potter and the Half-Blood Prince"}], "degree_detail"=>nil, "registered_at"=>"2015-11-01T14:41:09+0000"})
          expect(Jsoning(user)).to eq("{\"name\":\"Adam Baihaqi\",\"years_old\":21,\"gender\":\"male\",\"books\":[{\"name\":\"Quiet: The Power of Introvert\"},{\"name\":\"Harry Potter and the Half-Blood Prince\"}],\"degree_detail\":null,\"registered_at\":\"2015-11-01T14:41:09+0000\"}")
        end

        it "can convert time" do
          user.created_at = user.created_at.to_time 
          expect(user.created_at.class).to eq(Time)

          json_hash = Jsoning[user]
          expect(json_hash).to eq({"name"=>"Adam Baihaqi", "years_old"=>21, "gender"=>"male", "books"=>[{"name"=>"Quiet: The Power of Introvert"}, {"name"=>"Harry Potter and the Half-Blood Prince"}], "degree_detail"=>nil, "registered_at"=>"2015-11-01T21:41:09+0700"})
          json = Jsoning(user)
          expect(json).to eq("{\"name\":\"Adam Baihaqi\",\"years_old\":21,\"gender\":\"male\",\"books\":[{\"name\":\"Quiet: The Power of Introvert\"},{\"name\":\"Harry Potter and the Half-Blood Prince\"}],\"degree_detail\":null,\"registered_at\":\"2015-11-01T21:41:09+0700\"}")
        end

        it "can convert date" do
          user.created_at = user.created_at.to_date
          expect(user.created_at.class).to eq(Date)

          expect(Jsoning[user]).to eq({"name"=>"Adam Baihaqi", "years_old"=>21, "gender"=>"male", "books"=>[{"name"=>"Quiet: The Power of Introvert"}, {"name"=>"Harry Potter and the Half-Blood Prince"}], "degree_detail"=>nil, "registered_at"=>"2015-11-01T00:00:00+0000"})
          expect(Jsoning(user)).to eq("{\"name\":\"Adam Baihaqi\",\"years_old\":21,\"gender\":\"male\",\"books\":[{\"name\":\"Quiet: The Power of Introvert\"},{\"name\":\"Harry Potter and the Half-Blood Prince\"}],\"degree_detail\":null,\"registered_at\":\"2015-11-01T00:00:00+0000\"}")
        end
      end

      context "when default value is a proc" do
        it "can generate json" do
          user.books = nil
          json = Jsoning(user)
          expect(JSON.parse(json)).to eq({"name"=>"Adam Baihaqi", "years_old"=>21, "gender"=>"male", "books"=>[], "degree_detail"=>nil, "registered_at"=>"2015-11-01T14:41:09+0000"}) 
        end

        it "can generate json when default value is full-blown script" do
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

          user.books = nil
          json = Jsoning(user)
          expect(JSON.parse(json)).to eq({"name"=>"Adam Baihaqi", "years_old"=>21, "gender"=>"male", "books"=>[{"name"=>"Mathematics 6A"}, {"name"=>"Physics A2"}], "degree_detail"=>nil, "registered_at"=>"2015-11-01T14:41:09+0000"}) 
          expect(Jsoning.parse(json, My::User)).to eq({"name"=>"Adam Baihaqi", "years_old"=>21, "gender"=>"male", "books"=>[{"name"=>"Mathematics 6A"}, {"name"=>"Physics A2"}], "degree_detail"=>nil, "registered_at"=>"2015-11-01T14:41:09+0000"})
        end
      end
      it "can generate hash" do
        hash = Jsoning[user]
        expect(hash).to eq({"name"=>"Adam Baihaqi", "years_old"=>21, "gender"=>"male", "books"=>[{"name"=>"Quiet: The Power of Introvert"}, {"name"=>"Harry Potter and the Half-Blood Prince"}], "degree_detail"=>nil, "registered_at"=>"2015-11-01T14:41:09+0000"})

        user.taken_degree = degree

        hash = Jsoning[user]
        expect(hash).to eq({"name"=>"Adam Baihaqi", "years_old"=>21, "gender"=>"male", "books"=>[{"name"=>"Quiet: The Power of Introvert"}, {"name"=>"Harry Potter and the Half-Blood Prince"}], "degree_detail"=>{"faculty"=>"School of IT", "degree"=>"B.Sc. (Hons) Computer Science"}, "registered_at"=>"2015-11-01T14:41:09+0000"})
      end # can generate hash
    end # end without versioning context
  end
end
