module Asm
  class Evaluator
    def initialize(instruction_sequence, labels)
      @current_instruction = 0
      @registers = { ax: 0, bx: 0, cx: 0, dx: 0 }

      @labels = labels
      @instruction_sequence = instruction_sequence

      @jump_operations = { jmp: true, je: '==', jne: '!=', jl: '<',
        jle: '<=', jg: '>', jge: '>=' }.freeze

      @register_operations = { mov: '=', inc: '+', dec: '-', cmp: '==' }
    end

    def evaluate()
      while @current_instruction < @instruction_sequence.length
        instruction = @instruction_sequence[@current_instruction]

        if nil != @jump_operations[instruction['name']]
          jump @jump_operations[instruction['name']], *instruction['args']

        elsif nil != @register_operations[instruction['name']]
          calculate @register_operations[instruction['name']], *instruction['args']

        else
          send instruction['name'], *instruction['args']
        end
      end
    end

    def registers()
      @registers
    end

    def value_of(source)
      case source
        when Symbol then value = @registers[source]
        else value = source
      end
    end

    def jump(cond, where)
      if cond == true or @last_cmp.send(cond.to_sym, 0) == true
         case where
            when Symbol then @current_instruction = @labels[where]
            else @current_instruction = where
          end
      else
        @current_instruction += 1
      end
    end

    def calculate(op, destination, source = 1)
      @current_instruction += 1
      value = value_of source
      case op
        when '=' then @registers[destination] = value
        when '==' then @last_cmp = @registers[destination] <=> value
        else @registers[destination] = @registers[destination].send(op.to_sym, value)
      end
    end
  end

  class ScriptParser
    def initialize(&block)
      @instruction_sequence = []
      @labels = {}
      instance_eval &block
    end

    def labels()
      @labels
    end

    def instruction_sequence()
      @instruction_sequence
    end

    private

    def method_missing(name, *args)
      instructions = [:mov, :inc, :dec, :cmp, :jmp, :je, :jne, :jl, :jle, :jg, :jge]
      if nil != instructions.find_index(name)
        @instruction_sequence << { 'name' => name, 'args' => args }
      else
        name
      end
    end

    def label(name)
      @labels[name] = @instruction_sequence.size
    end

  end

  def self.asm(&block)
    script = ScriptParser.new(&block)
    instance = Evaluator.new(script.instruction_sequence, script.labels)

    instance.evaluate
    instance.registers.map { |key, value| value }
  end
end

a = Asm.asm do
  mov ax, 40
  mov bx, 32
  label cycle
  cmp ax, bx
  je finish
  dec ax
  jne cycle
  label finish
end

# def jump(cond, where)
  # if cond == true or @last_cmp.send cond.to_sym, 0 == true
     # case where
        # when Symbol
          # @current_instruction = @labels[where]
        # else
          # @current_instruction = where
      # end
  # else
    # @current_instruction += 1
  # end
# end

p a