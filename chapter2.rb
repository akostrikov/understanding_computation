# encoding: UTF-8
class Number < Struct.new(:value)
end
class Add < Struct.new(:left, :right)
end
class Multiply < Struct.new(:left, :right)
end






class Number
	def to_s
	value.to_s
	end
	def inspect
	"«#{self}»"
	end
end
class Add
	def to_s
	"#{left} + #{right}"
	end
	def inspect
	"«#{self}»"
	end
end

class Multiply
	def to_s
	"#{left} * #{right}"
	end
	def inspect
	"«#{self}»"
	end
end

class Number
def reducible?
false
end
end
class Add
def reducible?
true
end
end
class Multiply
def reducible?
true
end
end


def reducible?(expression)
case expression
when Number
false
when Add, Multiply
true
end
end



class Add
def reduce
if left.reducible?
Add.new(left.reduce, right)
elsif right.reducible?
Add.new(left, right.reduce)
else
Number.new(left.value + right.value)
end
end
end
class Multiply
def reduce
if left.reducible?
Multiply.new(left.reduce, right)
elsif right.reducible?
Multiply.new(left, right.reduce)
else
Number.new(left.value * right.value)
end
end
end

class Machine < Struct.new(:expression)
	def step
		self.expression = expression.reduce
	end
	def run
		while expression.reducible?
			puts expression
			step
		end
		puts expression
	end
end



class Boolean < Struct.new(:value)
	def to_s
	value.to_s
	end
	def inspect
		"«#{self}»"
	end
	def reducible?
		false
	end
	end
class LessThan < Struct.new(:left, :right)
	def to_s
		"#{left} < #{right}"
	end
	def inspect
		"«#{self}»"
	end
	def reducible?
		true
	end
	def reduce
		if left.reducible?
			LessThan.new(left.reduce, right)
		elsif right.reducible?
			LessThan.new(left, right.reduce)
		else
			Boolean.new(left.value < right.value)
		end
	end
end


class Variable < Struct.new(:name)
	def to_s
		name.to_s
	end
	def inspect
		"«#{self}»"
	end
	def reducible?
		true
	end
end


class Variable
	def reduce(environment)
		environment[name]
	end
end


class Add
	def reduce(environment)
		if left.reducible?
			Add.new(left.reduce(environment), right)
		elsif right.reducible?
			Add.new(left, right.reduce(environment))
		else
			Number.new(left.value + right.value)
		end
	end
end

class Multiply
	def reduce(environment)
		if left.reducible?
			Multiply.new(left.reduce(environment), right)
		elsif right.reducible?
			Multiply.new(left, right.reduce(environment))
		else
			Number.new(left.value * right.value)
		end
	end
end

class LessThan
	def reduce(environment)
		if left.reducible?
			LessThan.new(left.reduce(environment), right)
		elsif right.reducible?
			LessThan.new(left, right.reduce(environment))
		else
			Boolean.new(left.value < right.value)
		end
	end
end

Object.send(:remove_const, :Machine) 
class Machine < Struct.new(:expression, :environment)
	def step
		self.expression = expression.reduce(environment)
	end

	def run
		while expression.reducible?
			puts expression
			step
		end
		puts expression
	end
end
class DoNothing
	def to_s
		'do-nothing'
	end
	def inspect
		"«#{self}»"
	end
	def ==(other_statement)
		other_statement.instance_of?(DoNothing)
	end
	def reducible?
		false
	end
end


=begin
puts Add.new(Multiply.new(Number.new(1), Number.new(2)), Multiply.new(Number.new(3), Number.new(4)))
puts " Number.new(1).reducible? #{ Number.new(1).reducible?}"
puts " Add.new(Number.new(1), Number.new(2)).reducible? #{ Add.new(Number.new(1), Number.new(2)).reducible?}"

expression =
Add.new(
Multiply.new(Number.new(1), Number.new(2)),
Multiply.new(Number.new(3), Number.new(4))
)


puts Machine.new(
Add.new(
Multiply.new(Number.new(1), Number.new(2)),
Multiply.new(Number.new(3), Number.new(4)))).run.to_s << "MACHINE RUN"


puts Machine.new(
LessThan.new(Number.new(5), Add.new(Number.new(2), Number.new(2)))
).run.to_s << "LESS THAN!"
=end
class Assign < Struct.new(:name, :expression)
	def to_s
		"#{name} = #{expression}"
	end
	def inspect
		"«#{self}»"
	end
	def reducible?
		true
	end
	def reduce(environment)
		if expression.reducible?
			[Assign.new(name, expression.reduce(environment)), environment]
		else
			[DoNothing.new, environment.merge({ name => expression })]
		end
	end
end


#Machine.new(
#Add.new(Variable.new(:x), Variable.new(:y)), { x: Number.new(3), y: Number.new(4) }).run


statement = Assign.new(:x, Add.new(Variable.new(:x), Number.new(1)))
environment = { x: Number.new(2) }



statement, environment = statement.reduce(environment)
puts statement
puts environment

statement, environment = statement.reduce(environment)
statement, environment = statement.reduce(environment)
puts statement
puts statement.reducible?
puts environment

Object.send(:remove_const, :Machine)


class Machine < Struct.new(:statement, :environment)
	def step
		self.statement, self.environment = statement.reduce(environment)
	end
	def run
		while statement.reducible?
			puts "#{statement}, #{environment}"
			step
		end
			puts "#{statement}, #{environment}"
	end
end
Machine.new(
Assign.new(:x, Add.new(Variable.new(:x), Number.new(1))),
{ x: Number.new(2) }
).run


class If < Struct.new(:condition, :consequence, :alternative)
	def to_s
		"if (#{condition}) { #{consequence} } else { #{alternative} }"
	end
	def inspect
		"«#{self}»"
	end
	def reducible?
		true
	end
	def reduce(environment)
		if condition.reducible?
			[If.new(condition.reduce(environment), consequence, alternative), environment]
		else
		case condition
			when Boolean.new(true)
				[consequence, environment]
			when Boolean.new(false)
				[alternative, environment]
		end
		end
	end
end


Machine.new(
If.new(
Variable.new(:x),
Assign.new(:y, Number.new(1)),
Assign.new(:y, Number.new(2))
),
{ x: Boolean.new(true) }
).run

Machine.new(
If.new(Variable.new(:x), Assign.new(:y, Number.new(1)), DoNothing.new),
{ x: Boolean.new(false) }
).run


class Sequence < Struct.new(:first, :second)
	def to_s
		"#{first}; #{second}"
	end
	def inspect
		"«#{self}»"
	end
	def reducible?
		true
	end
	def reduce(environment)
		case first
			when DoNothing.new
				[second, environment]
			else
				reduced_first, reduced_environment = first.reduce(environment)
				[Sequence.new(reduced_first, second), reduced_environment]
		end
	end
end


Machine.new(
Sequence.new(
Assign.new(:x, Add.new(Number.new(1), Number.new(1))),
Assign.new(:y, Add.new(Variable.new(:x), Number.new(3)))
),
{}
).run



class While < Struct.new(:condition, :body)
	def to_s
		"while (#{condition}) { #{body} }"
	end
	def inspect
		"«#{self}»"
	end
	def reducible?
		true
	end
	def reduce(environment)
		[If.new(condition, Sequence.new(body, self), DoNothing.new), environment]
	end
end

Machine.new(
While.new(
LessThan.new(Variable.new(:x), Number.new(5)),
Assign.new(:x, Multiply.new(Variable.new(:x), Number.new(3)))
),
{ x: Number.new(1) }
).run


# BIG STEP SEMANTICS
class Number
	def evaluate(environment)
		self
	end
end
class Boolean
	def evaluate(environment)
		self
	end
end

class Variable
	def evaluate(environment)
		environment[name]
	end
end


class Add
	def evaluate(environment)
		Number.new(left.evaluate(environment).value + right.evaluate(environment).value)
	end
end

class Multiply
	def evaluate(environment)
		Number.new(left.evaluate(environment).value * right.evaluate(environment).value)
	end
end

class LessThan
	def evaluate(environment)
		Boolean.new(left.evaluate(environment).value < right.evaluate(environment).value)
	end
end

class Assign
	def evaluate(environment)
		environment.merge({ name => expression.evaluate(environment) })
	end
end

class DoNothing
	def evaluate(environment)
		environment
	end
end

class If
	def evaluate(environment)
		case condition.evaluate(environment)
			when Boolean.new(true)
				consequence.evaluate(environment)
			when Boolean.new(false)
				alternative.evaluate(environment)
		end
	end
end

class Sequence
	def evaluate(environment)
		second.evaluate(first.evaluate(environment))
	end
end



statement =
Sequence.new(
Assign.new(:x, Add.new(Number.new(1), Number.new(1))),
Assign.new(:y, Add.new(Variable.new(:x), Number.new(3)))
)


class While
	def evaluate(environment)
		case condition.evaluate(environment)
			when Boolean.new(true)
				evaluate(body.evaluate(environment))
			when Boolean.new(false)
				environment
		end
	end
end
RubyVM::InstructionSequence.compile_option = {
	tailcall_optimization: true,
	trace_instruction: false
}


statement =
While.new(
LessThan.new(Variable.new(:x), Number.new(5)),
Assign.new(:x, Multiply.new(Variable.new(:x), Number.new(3)))
)


# DENOTATIONAL
class Number
	def to_ruby
		"-> e { #{value.inspect} }"
	end
end
class Boolean
	def to_ruby
		"-> e { #{value.inspect} }"
	end
end


proc = eval(Number.new(5).to_ruby)
puts  proc.call({})

class Variable
	def to_ruby
	"-> e { e[#{name.inspect}] }"
	end
end

class Add
	def to_ruby
		"-> e { (#{left.to_ruby}).call(e) + (#{right.to_ruby}).call(e) }"
	end
end

class Multiply
	def to_ruby
		"-> e { (#{left.to_ruby}).call(e) * (#{right.to_ruby}).call(e) }"
	end
end

class LessThan
	def to_ruby
		"-> e { (#{left.to_ruby}).call(e) < (#{right.to_ruby}).call(e) }"
	end
end

 Add.new(Variable.new(:x), Number.new(1)).to_ruby


environment = { x: 3 }

proc = eval(Add.new(Variable.new(:x), Number.new(1)).to_ruby)
puts proc.call(environment)

class Assign
	def to_ruby
		"-> e { e.merge({ #{name.inspect} => (#{expression.to_ruby}).call(e) }) }"
	end
end

class DoNothing
	def to_ruby
	'-> e { e }'
	end
end

class If
def to_ruby
"-> e { if (#{condition.to_ruby}).call(e)" +
" then (#{consequence.to_ruby}).call(e)" +
" else (#{alternative.to_ruby}).call(e)" +
" end }"
end
end


class Sequence
	def to_ruby
	"-> e { (#{second.to_ruby}).call((#{first.to_ruby}).call(e)) }"
	end
end

class While
	def to_ruby
		"-> e {" +
		" while (#{condition.to_ruby}).call(e); e = (#{body.to_ruby}).call(e); end;" +
		" e" +
		" }"
	end
end

statement =
While.new(
LessThan.new(Variable.new(:x), Number.new(5)),
Assign.new(:x, Multiply.new(Variable.new(:x), Number.new(3)))
)
proc = eval(statement.to_ruby)

#<Proc (lambda)>
puts proc.call({ x: 1 })




# PARSER
require 'treetop'
Treetop.load('simple')
parse_tree = SimpleParser.new.parse('while (x < 5) { x = x * 3 }')
puts  parse_tree
statement = parse_tree.to_ast
puts statement.to_ruby
puts eval(statement.to_ruby).call({x: 1})

expression = SimpleParser.new.parse('1 * 2 * 3 * 4', root: :expression).to_ast
puts  expression.left

puts expression.right
