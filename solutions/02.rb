module StringUtils
  def StringUtils.strToSym(string)
    string.downcase.to_sym if string != nil
  end

  def StringUtils.stripSplit(string, delimeters)
    string.split(delimeters).each { |line| line.strip! }
  end
end

class Task < Hash
  include StringUtils

  attr_reader :status, :description, :priority, :tags
  def initialize(status, description, priority, tags)
    @status = self[:status] = StringUtils.strToSym status
    @description = self[:description] = description
    @priority = self[:priority] = StringUtils.strToSym priority
    @tags = self[:tags] = StringUtils.stripSplit(tags, ",") if tags != nil
  end

  def self.parseLine(stringLine)
    tokens = StringUtils.stripSplit(stringLine, "|")
    Task.new(tokens[0], tokens[1], tokens[2], tokens[3])
  end

  def filterTask(criteria)
    !criteria.arrayOfCriterias.select { |c| filterTaskHelper c }.empty?
  end

  def filterTaskHelper(container)
    shouldInclude = container.include.all? { |c, v| includes?(self[c], v) }
    shouldInclude &= container.exclude.all? { |c, v| excludes?(self[c], v) }
  end

  def includes?(a, b)
    if a.is_a?(Array)
      (a & b).size == b.size
    else
      a == b or b == nil
    end
  end

  def excludes?(a, b)
    if a.is_a?(Array)
      a & b == []
    else
      a != b
    end
  end
end

class CriteriaContainer
  attr_reader :include, :exclude

  def initialize(status, priority, tags)
    @include = { status: status, priority: priority, tags: tags }
    @exclude = { status: nil, priority: nil, tags: [] }
  end

  def &(other)
    intersectStatus other
    intersectPriority other
    intersectTags other
    self
  end

  def intersectStatus(other)
    @include[:status] = other.include[:status] if @include[:status] == nil
    @exclude[:status] = other.exclude[:status] if @exclude[:status] == nil
  end

  def intersectPriority(other)
    @include[:priority] = other.include[:priority] if @include[:priority] == nil
    @exclude[:priority] = other.exclude[:priority] if @exclude[:priority] == nil
  end

  def intersectTags(other)
    @include[:tags] |= other.include[:tags]
    @exclude[:tags] |= other.exclude[:tags]
  end

  def negateCriteria
    @include, @exclude = @exclude, @include
  end
end

class Criteria
  attr_reader :arrayOfCriterias

  def initialize(status: nil, priority: nil, tags: [])
    @arrayOfCriterias = []
    newCriteria = CriteriaContainer.new(status, priority, tags)
    @arrayOfCriterias << newCriteria
  end

  def self.method_missing(name, *args)
    case name.to_s
      when "status" then Criteria.new(status: args[0])
      when "priority" then Criteria.new(priority: args[0])
      when "tags" then Criteria.new(tags: args[0])
    end
  end

  def conjunct(element)
    @arrayOfCriterias.map { |criteria| criteria & element }
  end

  def &(other)
    other.arrayOfCriterias.each { |c| @arrayOfCriterias += conjunct c }
    self
  end

  def |(other)
    @arrayOfCriterias += other.arrayOfCriterias
    self
  end

  def !
    @arrayOfCriterias.each { |criteria| criteria.negateCriteria }
    @arrayOfCriterias = [@arrayOfCriterias.reduce { :& }]
    self
  end
end

class TodoList
  include Enumerable
  include StringUtils

  attr_reader :tasks
  @tasks = []
  def initialize(tasks)
    @tasks = tasks if tasks.is_a?(Array)
  end

  def each(&block)
    @tasks.each(&block)
  end

  def method_missing(name)
    case name.to_s
      when "tasks_todo" then select_by_status :todo
      when "tasks_in_progress" then select_by_status :current
      when "tasks_completed" then select_by_status :done
    end
  end

  def self.parse(text)
    tasks = []
    text.each_line { |line| tasks << Task.parseLine(line) }
    TodoList.new(tasks)
  end

  def completed?
    @tasks.select { |task| task[:status] != :done }.length == 0
  end

  def filter(criteria)
    self.class.new(@tasks.select { |task| task.filterTask criteria })
  end

  def adjoin(list)
    newTasks = []
    each { |task| newTasks << task }
    list.each { |task| newTasks |= [task] }
    self.class.new(newTasks)
  end

  private

  def select_by_status(status)
    @tasks.select { |task| task[:status] == status } .size
  end
end