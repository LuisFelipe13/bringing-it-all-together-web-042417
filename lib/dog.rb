require "pry"

class Dog
  attr_accessor :name, :breed
  attr_reader :id

  def initialize(args)
    if args.class == Hash
      args.each do |key, value|
        @id = value if key == :id
        @name = value if key == :name
        @breed = value if key == :breed
      end
    elsif args.class == Array
      @id = args[0]
      @name = args[1]
      @breed = args[2]
    end
  end

  def self.create_table
    sql = <<-SQL
      CREATE TABLE IF NOT EXISTS dogs (
        id INTEGER PRIMARY KEY,
        name TEXT,
        breed TEXT
      )
    SQL

    DB[:conn].execute(sql)
  end

  def self.drop_table
    sql = "DROP TABLE IF EXISTS dogs"
    DB[:conn].execute(sql)
  end

  def self.new_from_db(row)
    self.new(row)
  end

  def self.find_by_name(name)
    sql = <<-SQL
      SELECT * FROM dogs WHERE name = ? LIMIT 1
    SQL
    test = DB[:conn].execute(sql,name).first
    new_from_db(test)
  end

  def update
    sql = "UPDATE dogs SET name = ?, breed = ? WHERE id = ?"
    DB[:conn].execute(sql, self.name, self.breed, self.id)
  end

  def save
    if self.id
      self.update
    else
      sql = <<-SQL
        INSERT INTO dogs (name, breed)
        VALUES (?, ?)
      SQL

      DB[:conn].execute(sql, self.name, self.breed)
      @id = DB[:conn].execute("SELECT last_insert_rowid() FROM dogs")[0][0]
    end
    self
  end

  def self.create(args)
    dog = Dog.new(args)
    dog.save
    dog
  end

  def self.find_by_id(num)
    sql = <<-SQL
      SELECT * FROM dogs WHERE id = ? LIMIT 1
    SQL
    test = DB[:conn].execute(sql,num).first
    new_from_db(test)
  end

  def self.find_or_create_by(name:, breed:)
    dog = DB[:conn].execute("SELECT * FROM dogs WHERE name = ? AND breed = ?", name, breed)
    if !dog.empty?
      dog_data = dog[0]
      dog = Dog.new(dog_data)
    else
      dog = self.create(name: name, breed: breed)
    end
    dog
  end
end
