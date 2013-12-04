class FARule < Struct.new(:state, :character, :next_state)
  def applies_to?(state, character)
    self.state == state && self.character == character
  end
  def follow
    next_state
  end
  def inspect
    "#<FARule #{state.inspect} --#{character}--> #{next_state.inspect}>"
  end
end

class DFARulebook < Struct.new(:rules)
  def next_state(state, character)
   rule_for(state, character).follow
  end

  def rule_for(state, character)
   rules.detect { |rule| rule.applies_to?(state, character) }
  end
end

rulebook = DFARulebook.new([
  FARule.new(1, 'a', 2), FARule.new(1, 'b', 1),
  FARule.new(2, 'a', 2), FARule.new(2, 'b', 3),
  FARule.new(3, 'a', 3), FARule.new(3, 'b', 3)
])
puts rulebook.next_state(1, 'a')

class DFA < Struct.new(:current_state, :accept_states, :rulebook)
  def accepting?
    accept_states.include?(current_state)
  end
end

class DFA
  def read_character(character)
    self.current_state = rulebook.next_state(current_state, character)
  end
end

class DFA
  def read_string(string)
    string.chars.each do |character|
      read_character(character)
    end
  end
end


puts DFA.new(1, [1, 3], rulebook).accepting?

puts DFA.new(1, [3], rulebook).accepting?

dfa = DFA.new(1, [3], rulebook)
puts dfa.accepting?

dfa.read_character('b');
puts dfa.accepting?

3.times do dfa.read_character('a') end
puts dfa.accepting?

dfa.read_character('b');
puts dfa.accepting?

dfa = DFA.new(1, [3], rulebook); 
puts dfa.accepting?

dfa.read_string('baaab');
puts dfa.accepting?

class DFADesign < Struct.new(:start_state, :accept_states, :rulebook)
  def to_dfa
    DFA.new(start_state, accept_states, rulebook)
  end
  def accepts?(string)
    to_dfa.tap { |dfa| dfa.read_string(string) }.accepting?
  end
end

dfa_design = DFADesign.new(1, [3], rulebook)

puts dfa_design.accepts?('a')
puts dfa_design.accepts?('baba')



require 'set'
class NFARulebook < Struct.new(:rules)
  def next_states(states, character)
    states.flat_map { |state| follow_rules_for(state, character) }.to_set
  end
  def follow_rules_for(state, character)
    rules_for(state, character).map(&:follow)
  end
  def rules_for(state, character)
    rules.select { |rule| rule.applies_to?(state, character) }
  end
end
rulebook = NFARulebook.new([
  FARule.new(1, 'a', 1), FARule.new(1, 'b', 1), FARule.new(1, 'b', 2),
  FARule.new(2, 'a', 3), FARule.new(2, 'b', 3),
  FARule.new(3, 'a', 4), FARule.new(3, 'b', 4)
])
rulebook.next_states(Set[1], 'b')
rulebook.next_states(Set[1, 2], 'a')
rulebook.next_states(Set[1, 3], 'b')

class NFA < Struct.new(:current_states, :accept_states, :rulebook)
  def accepting?
    (current_states & accept_states).any?
  end
end

puts "should be false"
puts NFA.new(Set[1], [4], rulebook).accepting?

puts "should be true"
puts NFA.new(Set[1, 2, 4], [4], rulebook).accepting?

class NFA
  def read_character(character)
    self.current_states = rulebook.next_states(current_states, character)
  end
  def read_string(string)
    string.chars.each do |character|
      read_character(character)
    end
  end
end

class NFADesign < Struct.new(:start_state, :accept_states, :rulebook)
  def accepts?(string)
    to_nfa.tap { |nfa| nfa.read_string(string) }.accepting?
  end
  def to_nfa
    NFA.new(Set[start_state], accept_states, rulebook)
  end
end

nfa_design = NFADesign.new(1, [4], rulebook)

puts "should be true"
puts nfa_design.accepts?('bab')

class NFARulebook
  def follow_free_moves(states)
    more_states = next_states(states, nil)
    if more_states.subset?(states)
      states
    else
      follow_free_moves(states + more_states)
    end
  end
end

puts "should be <Set: {1, 2, 4}>"
puts  rulebook.follow_free_moves(Set[1]).inspect

class NFA
  def current_states
    rulebook.follow_free_moves(super)
  end
end

nfa_design = NFADesign.new(1, [2, 4], rulebook)
puts 'should be true'
puts nfa_design.accepts?('aa')
puts 'should be true'
puts nfa_design.accepts?('aaa')
puts 'should be false'
puts nfa_design.accepts?('aaaaa')
puts 'should be true'
puts nfa_design.accepts?('aaaaaa')

module Pattern
def bracket(outer_precedence)
if precedence < outer_precedence
'(' + to_s + ')'
else
to_s
end
end
def inspect
"/#{self}/"
end
end
class Empty
include Pattern
def to_s
''
end
def precedence
  3
end
end

class Literal < Struct.new(:character)
include Pattern
def to_s
character
end
def precedence
  3
end
end
class Concatenate < Struct.new(:first, :second)
include Pattern
def to_s
  [first, second].map { |pattern| pattern.bracket(precedence) }.join
end
def precedence
  1
end
end

class Choose < Struct.new(:first, :second)
include Pattern
def to_s
  [first, second].map { |pattern| pattern.bracket(precedence) }.join('|')
end
def precedence
  0
end
end

class Repeat < Struct.new(:pattern)
include Pattern
def to_s
  pattern.bracket(precedence) + '*'
end
def precedence
  2
end
end

pattern =
Repeat.new(
Choose.new(
Concatenate.new(Literal.new('a'), Literal.new('b')),
Literal.new('a')
)
)
puts  /(ab|a)*/
puts pattern .inspect
class Empty
  def to_nfa_design
    start_state = Object.new
    accept_states = [start_state]
    rulebook = NFARulebook.new([])
    NFADesign.new(start_state, accept_states, rulebook)
  end
end
class Literal
  def to_nfa_design
    start_state = Object.new
    accept_state = Object.new
    rule = FARule.new(start_state, character, accept_state)
    rulebook = NFARulebook.new([rule])
    NFADesign.new(start_state, [accept_state], rulebook)
  end
end

module Pattern
  def matches?(string)
    to_nfa_design.accepts?(string)
  end
end

puts 'should be false'
puts Empty.new.matches?('a')

puts 'should be true'
puts Literal.new('a').matches?('a')
class Concatenate
  def to_nfa_design
    first_nfa_design = first.to_nfa_design
    second_nfa_design = second.to_nfa_design
    start_state = first_nfa_design.start_state
    accept_states = second_nfa_design.accept_states
    rules = first_nfa_design.rulebook.rules + second_nfa_design.rulebook.rules
    extra_rules = first_nfa_design.accept_states.map { |state|
    FARule.new(state, nil, second_nfa_design.start_state)
    }
    rulebook = NFARulebook.new(rules + extra_rules)
    NFADesign.new(start_state, accept_states, rulebook)
  end
end


pattern = Concatenate.new(Literal.new('a'), Literal.new('b'))

puts "/ab/"
puts false
puts pattern.matches?('a')
puts true
puts pattern.matches?('ab')
puts false
puts pattern.matches?('abc')

class Choose
  def to_nfa_design
    first_nfa_design = first.to_nfa_design
    second_nfa_design = second.to_nfa_design
    start_state = Object.new
    accept_states = first_nfa_design.accept_states + second_nfa_design.accept_states
    rules = first_nfa_design.rulebook.rules + second_nfa_design.rulebook.rules
    extra_rules = [first_nfa_design, second_nfa_design].map { |nfa_design|
    FARule.new(start_state, nil, nfa_design.start_state)
    }
    rulebook = NFARulebook.new(rules + extra_rules)
    NFADesign.new(start_state, accept_states, rulebook)
  end
end

class Repeat
  def to_nfa_design
    pattern_nfa_design = pattern.to_nfa_design
    start_state = Object.new
    accept_states = pattern_nfa_design.accept_states + [start_state]
    rules = pattern_nfa_design.rulebook.rules
    extra_rules =
    pattern_nfa_design.accept_states.map { |accept_state|
    FARule.new(accept_state, nil, pattern_nfa_design.start_state)
    } +
    [FARule.new(start_state, nil, pattern_nfa_design.start_state)]
    rulebook = NFARulebook.new(rules + extra_rules)
    NFADesign.new(start_state, accept_states, rulebook)
  end
end
require 'treetop'


Treetop.load('pattern')


parse_tree = PatternParser.new.parse('(a(|b))*')

pattern = parse_tree.to_ast
puts "pattern"
puts pattern.inspect
puts pattern.matches?('abaab')

class NFARulebook
def alphabet
rules.map(&:character).compact.uniq
end
end

class NFASimulation
def rules_for(state)
nfa_design.rulebook.alphabet.map { |character|
FARule.new(state, character, next_state(state, character))
}
end
end
class NFASimulation < Struct.new(:nfa_design)
def next_state(state, character)
nfa_design.to_nfa(state).tap { |nfa|
nfa.read_character(character)
}.current_states
end
end

class NFASimulation
def discover_states_and_rules(states)
rules = states.flat_map { |state| rules_for(state) }
more_states = rules.map(&:follow).to_set
if more_states.subset?(states)
[states, rules]
else
discover_states_and_rules(states + more_states)
end
end
end

class NFASimulation
def to_dfa_design
start_state = nfa_design.to_nfa.current_states
states, rules = discover_states_and_rules(Set[start_state])
accept_states = states.select { |state| nfa_design.to_nfa(state).accepting? }
DFADesign.new(start_state, accept_states, DFARulebook.new(rules))
end
end
