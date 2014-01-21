module StringUtils
  def StringUtils.strToSym(string)
    string.downcase.to_sym if string != nil
  end

  def StringUtils.stripSplit(string, delimeters)
    tokensArray = []
    tokensArray = string.split delimeters
    tokensArray.each { |line| line.strip!}
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
    shouldInclude = container.include.all? { |c, v| checkInclude(self[c], v) }
    shouldInclude &= container.exclude.all? { |c, v| checkExclude(self[c], v) }
  end

  def checkInclude(a, b)
    if a.is_a?(Array)
      (a & b).size == b.size
    else
      a == b or b == nil
    end
  end

  def checkExclude(a, b)
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

  def self.status(s)
    Criteria.new(status: s)
  end

  def self.priority(p)
    Criteria.new(priority: p)
  end

  def self.tags(t)
    Criteria.new(tags: t)
  end

  def conjunct(element)
    criterias = []
    @arrayOfCriterias.each { |criteria| criterias << (criteria & element) }
    criterias
  end

  def &(other)
    criterias = []
    other.arrayOfCriterias.each { |criteria| criterias += conjunct criteria }
    @arrayOfCriterias = criterias
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

  def tasks_todo
    @tasks.select { |task| task[:status] == :todo } .size
  end

  def tasks_in_progress
    @tasks.select { |task| task[:status] == :current } .size
  end

  def tasks_completed
    @tasks.select { |task| task[:status] == :done } .size
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
end

text_input =       "TODO    | Eat spaghetti.               | High   | food, happiness
TODO    | Get 8 hours of sleep.        | Low    | health
CURRENT | Party animal.                | Normal | socialization
CURRENT | Grok Ruby.                   | High   | development, ruby
DONE    | Have some tea.               | Normal |
TODO    | Destroy Facebook and Google. | High   | save humanity, conspiracy
DONE    | Do the 5th Ruby challenge.   | High   | ruby course, FMI, development, ruby
TODO    | Find missing socks.          | Low    |"
todo_list = TodoList.parse(text_input)

# todo_list.each { |task| p task}

# p todo_list.completed?
# p todo_list.tasks_todo
# p todo_list.tasks_completed
# p todo_list.tasks_in_progress
# p "------------------"
# todo_list.adjoin(TodoList.new(todo_list.tasks)).each { |task| p task }
# p "------------------"
# p Criteria.priority(:high)
# p "------------------"
# p Criteria.priority(:low) | Criteria.priority(:high)
# p "------------------"
# p Criteria.priority(:low) | Criteria.priority(:high) & Criteria.tags(["wtf"]) | Criteria.status(:done) | Criteria.status(:current)
# p "------------------"
# p Criteria.priority(:high) & Criteria.tags(["development"])
# todo_list.filter(Criteria.priority(:high) & Criteria.tags(["development", "ruby"])).each { |t| p t} #Criteria.priority(:high).each { |t| p t}
# food, doge, herp sad
development = todo_list.filter (Criteria.tags(['development']))
development.each { |t| p t }
food = todo_list.filter (Criteria.tags(['food']))
food.each { |t| p t }
adjoined = development.adjoin food
adjoined.each { |t| p t }