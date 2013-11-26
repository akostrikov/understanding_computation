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



