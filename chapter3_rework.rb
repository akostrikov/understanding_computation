puts

class FARule < Struct.new(:state, :character, :next_state)
  def applies_to?(state, character)
    self.state == state && self.character == character
  end
  def follow
    next_state
  end
  def inspect
    "#FARule #{state.inspect} -- #{character} --> #{next_state.inspect}"
  end
end
class DFARulebook < Struct.new(:rules)
  def next_state(state, character)
    rule_for(state, character).follow
  end
  def rule_for(state, character)
    rules.detect { |rule| rule.applies_to?(state, character)}
  end
end
class DFA < Struct.new(:current_state, :accept_states, :rulebook)
  def accepting?
    accept_states.include?(current_state)
  end
  def read_character(character)
    self.current_state = rulebook.next_state(current_state, character)
  end
  def read_string(string)
    string.chars.each do |character|
      read_character(character)
    end
  end
end
class DFADesign < Struct.new(:start_state, :accept_states, :rulebook)
  def to_dfa
    DFA.new(start_state, accept_states, rulebook)
  end
  def accepts?(string)
    to_dfa.tap { |dfa| dfa.read_string(string) }.accepting?
  end
end

rulebook = DFARulebook.new([
  FARule.new(1, 'a', 2),
  FARule.new(1, 'b', 1),
  FARule.new(2, 'a', 2),
  FARule.new(2, 'b', 3),
  FARule.new(3, 'a', 3),
  FARule.new(3, 'b', 3)])
dfa = DFA.new(1, [3], rulebook)
puts dfa.accepting?

dfa.read_string('baaab')
puts dfa.accepting?

dfa_design = DFADesign.new(1, [3], rulebook)
puts dfa_design.accepts?('baba')

require 'set'

class NFARulebook < Struct.new(:rules)
  def next_states(states,character)
    states.flat_map { |state| follow_rules_for(state, character)}.to_set
  end

  def follow_rules_for(state, character)
    rules_for(state, character).map(&:follow)
  end

  def rules_for(state, character)
    rules.select { |rule| rule.applies_to?(state, character) }
  end
end

rulebook = NFARulebook.new([
  FARule.new(1, 'a', 1),
  FARule.new(1, 'b', 1),
  FARule.new(1, 'b', 2),
  FARule.new(2, 'a', 3),
  FARule.new(2, 'b', 3),
  FARule.new(3, 'a', 4),
  FARule.new(3, 'b', 4)])

puts rulebook.next_states(Set[1], 'b').inspect

class NFA < Struct.new(:current_states, :accept_states, :rulebook)
  def accepting?
    (current_states & accept_states).any?
  end
end

puts NFA.new(Set[1], [4], rulebook).accepting?
puts NFA.new(Set[1], [4], rulebook).accepting?

class NFA
  def read_character(character)
    self.current_states = rulebook.next_states(current_states, character)
  end

  def read_string(string)
    string.chars.each do |char|
      read_character(char)
    end
  end
end

nfa = NFA.new(Set[1], [4], rulebook)
puts nfa.accepting?
nfa.read_string('aabbb');
puts nfa.accepting?

class NFADesign < Struct.new(:start_state, :accept_states, :rulebook)
  def accepts?(string)
    to_nfa.tap { |nfa| nfa.read_string(string) }.accepting?
  end
  def to_nfa
    NFA.new(Set[start_state], accept_states, rulebook)
  end
end


nfa_design = NFADesign.new(1, [4], rulebook)
puts  nfa_design.accepts?('bab')

rulebook = NFARulebook.new([
  FARule.new(1, nil, 2),
  FARule.new(1, nil, 4),
  FARule.new(2, 'a', 3),
  FARule.new(3, 'a', 2),
  FARule.new(4, 'a', 5),
  FARule.new(5, 'a', 6),
  FARule.new(6, 'a', 4)])

puts rulebook.next_states(Set[1], nil).inspect

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

puts rulebook.follow_free_moves(Set[1]).inspect

class NFA
  def current_states
    rulebook.follow_free_moves(super)
  end
end

nfa_design = NFADesign.new(1, [2, 4], rulebook)
nfa_design.accepts?('aa')
nfa_design.accepts?('aaa')

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

pattern = Repeat.new(
    Choose.new(
        Concatenate.new(Literal.new('a'), Literal.new('b')),
        Literal.new('a') )
)
puts pattern

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


nfa_design = Empty.new.to_nfa_design
puts nfa_design.accepts?('')
puts nfa_design.accepts?('a')
module Pattern
  def matches?(string)
    to_nfa_design.accepts?(string)
  end
end

puts Empty.new.matches?('a')

class Concatenate
  def to_nfa_design
    first_nfa_design = first.to_nfa_design
    second_nfa_design = second.to_nfa_design

    start_state = first_nfa_design.start_state
    accept_states = second_nfa_design.accept_states

    rules = first_nfa_design.rulebook.rules + second_nfa_design.rulebook.rules
    extra_rules = first_nfa_design.accept_states.map { |state| FARule.new(state, nil, second_nfa_design.start_state) }
    rulebook = NFARulebook.new(rules + extra_rules)

    NFADesign.new(start_state, accept_states, rulebook)
  end
end

pattern = Concatenate.new(Literal.new('a'), Literal.new('b'))

puts pattern.matches?('ab')

class Choose
  def to_nfa_design
    first_nfa_design = first.to_nfa_design
    second_nfa_design = second.to_nfa_design
    start_state = Object.new

    accept_states = first_nfa_design.accept_states + second_nfa_design.accept_states
    rules = first_nfa_design.rulebook.rules + second_nfa_design.rulebook.rules

    extra_rules = [first_nfa_design, second_nfa_design].map { |nfa_design| FARule.new(start_state, nil, nfa_design.start_state) }
    rulebook = NFARulebook.new(rules + extra_rules)

    NFADesign.new(start_state, accept_states, rulebook)
  end
end

pattern = Choose.new(Literal.new('a'), Literal.new('b'))

puts pattern

puts pattern.matches?('a')

class Repeat
  def to_nfa_design
    pattern_nfa_design = pattern.to_nfa_design
    start_state = Object.new

    accept_states = pattern_nfa_design.accept_states + [start_state]
    rules = pattern_nfa_design.rulebook.rules

    extra_rules =
        pattern_nfa_design.accept_states.map { |accept_state| FARule.new(accept_state, nil, pattern_nfa_design.start_state) } +
            [FARule.new(start_state, nil, pattern_nfa_design.start_state)]

    rulebook = NFARulebook.new(rules + extra_rules)

    NFADesign.new(start_state, accept_states, rulebook)
  end
end

pattern = Repeat.new(Literal.new('a'))
puts pattern

puts pattern.matches?('aaaa')


require 'treetop'
Treetop.load('pattern')
tree = PatternParser.new.parse('(a(|b))*')
pattern = tree.to_ast
puts 'Pattern from ast matches? ' << pattern.matches?('abaab').to_s

class NFADesign
  def to_nfa(current_states = Set[start_state])
    NFA.new(current_states, accept_states, rulebook)
  end
end

rulebook = NFARulebook.new([
                               FARule.new(1, 'a', 1), FARule.new(1, 'a', 2), FARule.new(1, nil, 2), FARule.new(2, 'b', 3),
                               FARule.new(3, 'b', 1), FARule.new(3, nil, 2)
                           ])
nfa = nfa_design.to_nfa(Set[2, 3])
nfa.read_character('b');
puts nfa.current_states.inspect

class NFASimulation < Struct.new(:nfa_design)
  def next_state(state, character)
    nfa_design.to_nfa(state).tap { |nfa| nfa.read_character(character)}.current_states
  end
end

class NFARulebook
  def alphabet
    rules.map(&:character).compact.uniq
  end
end

class NFASimulation
  def rules_for(state)
    nfa_design.rulebook.alphabet.map { |character|
      FARule.new(state, character, next_state(state, character)) }
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

start_state = nfa_design.to_nfa.current_states
puts start_state.inspect

simulation = NFASimulation.new(nfa_design)
puts simulation.discover_states_and_rules(Set[start_state]).inspect

puts nfa_design.to_nfa(Set[1, 2]).accepting?

puts nfa_design.to_nfa(Set[2, 3]).accepting?

class NFASimulation
  def to_dfa_design
    start_state = nfa_design.to_nfa.current_states
    states, rules = discover_states_and_rules(Set[start_state])
    accept_states = states.select { |state| nfa_design.to_nfa(state).accepting? }
    DFADesign.new(start_state, accept_states, DFARulebook.new(rules))
  end
end


dfa_design = simulation.to_dfa_design
puts dfa_design.accepts?('aaa')

# In the worst case, though, an NFA with n states may require a DFA with 2n states,
# because there are a total of 2n possible combinations of n states—think of representing
# each combination as a different n-bit number, where the nth bit indicates whether state n
# is included in that combination—and the simulation might need to be able to visit all of them instead of just a few.

# Some DFAs have the property of being minimal, which means there’s no way to design a DFA with fewer states
# that will accept the same strings. The NFA-to-DFA conversion process can sometimes produce nonminimal DFAs that
# contain redundant states, but there’s an elegant way to eliminate this redundancy, known as Brzozowski’s algorithm:
# 1. Begin with your nonminimal DFA.
# 2. Reverse all of the rules.
# Visually, this means that every arrow in the machine’s diagram stays in the same place but points backward;
# in code terms, every FARule.new(state, character, next_state)is replaced with FARule.new(next_state, character, state).
# Reversing the rules usually breaks the determinism constraints, so now you have an NFA.
# 3. Exchange the roles of start and accept states: the start state becomes an accept state,
# and each of the accept states becomes a start state. (You can’t directly convert all the accept states
# into start states because an NFA can only have one start state, but you can get the same effect
# by creating a new start state and connecting it to each of the old accept states with a free move.)
# 4. Convert this reversed NFA to a DFA in the usual way.

# Surprisingly, the resulting DFA is guaranteed to be minimal and contain no redundant states.
# The unhappy downside is that it will only accept reversed versions of the original DFA’s strings:
# if our original DFA accepted the strings 'ab', 'aab', 'aaab', and so on,
# the minimized DFA will accept strings of the form 'ba', 'baa', and 'baaa'.
# The trick is to fix this by simply performing the whole procedure a second time, beginning with
# the reversed DFA and ending up with a double-reversed DFA,
# which is again guaranteed to be minimal but this time accepts the same strings as the machine we started with.

# It’s nice to have an automatic way of eliminating redundancy in a design,
# but interestingly, a minimized DFA is also canonical: any two DFAs that accept exactly the same strings
# will minimize to the same design, so we can check whether two DFAs are equivalent by minimizing them and comparing
# the resulting machine designs to see if they have the same structure.
# This in turn gives us an elegant way of checking whether two regular expressions are equivalent:
# if we convert two patterns that match the same strings (e.g., ab(ab)* and a(ba)*b) into NFAs,
# convert those NFAs into DFAs, then minimize both DFAs with Brzozowski’s algorithm,
# we’ll end up with two identical- looking machines.

# The semantic styles seen in this chapter go by many different names.
# Small-step semantics is also known as structural operational semantics and transition semantics;
# big-step semantics is more often called natural semantics or relational semantics;
# and denotational semantics is also called fixed-point semantics or mathematical semantics.

# Other styles of formal semantics are available. One alternative is axiomatic semantics, which describes the meaning
# of a statement by making assertions about the state of the abstract machine before and after that statement executes:
# if one assertion (the pre- condition) is initially true before the statement is executed, then the other assertion
# (the postcondition) will be true afterward. Axiomatic semantics is useful for verifying the correctness of programs:
# as statements are plugged together to make larger programs, their corresponding assertions can be plugged together
# to make larger assertions, with the goal of showing that an overall assertion about a program matches
# up with its intended specification.
# Although the details are different, axiomatic semantics is the style that best characterizes the RubySpec project,
# an “executable specification for the Ruby programming language” that uses RSpec-style assertions
# to describe the behavior of Ruby’s built-in
# language constructs, as well as its core and standard libraries.
# For example, here’s a fragment of RubySpec’s description of the Array#<< method

# Or, in the case of a mechanical computer like the Analytical Engine designed by Charles Babbage in 1837,
# cogs and paper obeying the laws of physics.
