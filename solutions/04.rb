module Asm
  class Evaluator
    JUMP_OPERATIONS = { jmp: true,
                        je: '==',
                        jne: '!=',
                        jl: '<',
                        jle: '<=',
                        jg: '>',
                        jge: '>='
                      }.freeze

    REGISTER_OPERATIONS = { mov: '=',
                            inc: '+',
                            dec: '-',
                            cmp: '=='
                          }.freeze

    def initialize(instruction_sequence, labels)
      @current_instruction = 0
      @registers = { ax: 0, bx: 0, cx: 0, dx: 0 }

      @labels = labels
      @instruction_sequence = instruction_sequence
    end

    def evaluate()
      while @current_instruction < @instruction_sequence.length
        instruction = @instruction_sequence[@current_instruction]

        if nil != JUMP_OPERATIONS[instruction['name']]
          jump JUMP_OPERATIONS[instruction['name']], *instruction['args']

        elsif nil != REGISTER_OPERATIONS[instruction['name']]
          calculate REGISTER_OPERATIONS[instruction['name']], *instruction['args']

        else
          send instruction['name'], *instruction['args']
        end
      end
    end

    def registers()
      @registers
    end

    def jump(cond, where)
      if cond == true or @last_cmp.send(cond.to_sym, 0) == true
        if where.is_a?(Symbol) then
          @current_instruction = @labels[where]
        else
          @current_instruction = where
        end
      else
        @current_instruction += 1
      end
    end

    def calculate(op, destination, source = 1)
      @current_instruction += 1
      if source.is_a?(Symbol) then source = @registers[source] end
      case op
        when '=' then @registers[destination] = source
        when '==' then @last_cmp = @registers[destination] <=> source
        else @registers[destination] = @registers[destination].send(op.to_sym, source)
      end
    end
  end

  class ScriptParser
    INSTRUCTIONS = [
                    :mov,
                    :inc,
                    :dec,
                    :cmp,
                    :jmp,
                    :je,
                    :jne,
                    :jl,
                    :jle,
                    :jg,
                    :jge,
                   ].freeze

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
      if nil != INSTRUCTIONS.find_index(name)
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