# This is a purely functional stack. The #push and #pop methods are nondestructive: they each return a new Stack instance
# rather than modifying the existing one. Creating a new object every time makes this implementation less efficient
# than a conventional stack with destructive #push and #pop operations
# (and we could just use Array directly if we wanted that) but also makes it easier to work with,
# because we don’t need to worry about the consequences of modifying a Stack that’s being used in more than one place.
class Stack < Struct.new(:contents)
  def push(character)
    Stack.new([character] + contents)
  end
  def pop
    Stack.new(contents.drop(1))
  end
  def top
    contents.first
  end
  def inspect
    "#<Stack (#{top})#{contents.drop(1).join}>"
  end
end

stack = Stack.new(['a', 'b', 'c', 'd', 'e'])

puts stack.top

puts stack.pop.pop.top

class PDAConfiguration < Struct.new(:state, :stack)
end

class PDARule < Struct.new(:state, :character, :next_state, :pop_character, :push_characters)
  def applies_to?(configuration, character)
    self.state == configuration.state &&
      self.pop_character == configuration.stack.top &&
      self.character == character
  end
end

rule = PDARule.new(1, '(', 2, '$', ['b', '$'])
configuration = PDAConfiguration.new(1, Stack.new(['$']))
rule.applies_to?(configuration, '(')

class PDARule
  def follow(configuration)
    PDAConfiguration.new(next_state, next_stack(configuration))
  end
  def next_stack(configuration)
    popped_stack = configuration.stack.pop
    push_characters.reverse.
        inject(popped_stack) { |stack, character| stack.push(character) }
  end
end

class DPDARulebook < Struct.new(:rules)
  def next_configuration(configuration, character)
    rule_for(configuration, character).follow(configuration)
  end
  def rule_for(configuration, character)
    rules.detect { |rule| rule.applies_to?(configuration, character) }
  end
end

rulebook = DPDARulebook.new([
                  PDARule.new(1, '(', 2, '$',['b', '$']),
                  PDARule.new(2, '(', 2, 'b',['b', 'b']),
                  PDARule.new(2, ')', 2, 'b',[]),
                  PDARule.new(2, nil, 1, '$',    ['$'])
])
configuration = rulebook.next_configuration(configuration, '(')

class DPDA < Struct.new(:current_configuration, :accept_states, :rulebook)
  def accepting?
    accept_states.include?(current_configuration.state)
  end
  def read_character(character)
    self.current_configuration = rulebook.next_configuration(current_configuration, character)
  end
  def read_string(string)
    string.chars.each do |character|
      read_character(character)
    end
  end
end

dpda = DPDA.new(PDAConfiguration.new(1, Stack.new(['$'])), [1], rulebook)
dpda.accepting?
dpda.read_string('(()'); dpda.accepting?

class DPDARulebook
  def applies_to?(configuration, character)
    !rule_for(configuration, character).nil?
  end
  def follow_free_moves(configuration)
    if applies_to?(configuration, nil)
      follow_free_moves(next_configuration(configuration, nil))
    else
      configuration
    end
  end
end

configuration = PDAConfiguration.new(2, Stack.new(['$']))
rulebook.follow_free_moves(configuration)

class DPDA
  def current_configuration
    rulebook.follow_free_moves(super)
  end
end

dpda = DPDA.new(PDAConfiguration.new(1, Stack.new(['$'])), [1], rulebook)
dpda.read_string('(()('); dpda.accepting?

dpda_design = DPDADesign.new(1, '$', [1], rulebook)
dpda_design.accepts?('(((((((((())))))))))')

class PDAConfiguration
  STUCK_STATE = Object.new
  def stuck
    PDAConfiguration.new(STUCK_STATE, stack)
  end
  def stuck?
    state == STUCK_STATE
  end
end

class DPDA
  def next_configuration(character)
    if rulebook.applies_to?(current_configuration, character)
      rulebook.next_configuration(current_configuration, character)
    else
      current_configuration.stuck
    end
  end
  def stuck?
    current_configuration.stuck?
  end
  def read_character(character)
    self.current_configuration = next_configuration(character)
  end
  def read_string(string) string.chars.each do |character|
    read_character(character) unless stuck? end
  end
end

dpda = DPDA.new(PDAConfiguration.new(1, Stack.new(['$'])), [1], rulebook)
dpda.read_string('())'); dpda.current_configuration
dpda.accepting?
dpda.stuck?
dpda_design.accepts?('())')

require 'set'

class NPDARulebook < Struct.new(:rules)
  def next_configurations(configurations, character)
    configurations.flat_map { |config| follow_rules_for(config, character) }.to_set
  end
  def follow_rules_for(configuration, character)
    rules_for(configuration, character).map { |rule| rule.follow(configuration) }
  end
  def rules_for(configuration, character)
    rules.select { |rule| rule.applies_to?(configuration, character) }
  end
end

class NPDARulebook
  def follow_free_moves(configurations)
    more_configurations = next_configurations(configurations, nil)
    if more_configurations.subset?(configurations)
      configurations
    else
      follow_free_moves(configurations + more_configurations)
    end
  end
end


class NPDA < Struct.new(:current_configurations, :accept_states, :rulebook)
  def accepting?
    current_configurations.any? { |config| accept_states.include?(config.state) }
  end
  def read_character(character)
    self.current_configurations = rulebook.next_configurations(current_configurations, character)
  end
  def read_string(string)
    string.chars.each do |character|
      read_character(character)
    end
  end
  def current_configurations
    rulebook.follow_free_moves(super)
  end
end


rulebook = NPDARulebook.new([
PDARule.new(1, 'a', 1, '$',['a', '$']),
PDARule.new(1, 'a', 1, 'a',['a', 'a']),
PDARule.new(1, 'a', 1, 'b',['a', 'b']),
PDARule.new(1, 'b', 1, '$',['b', '$']),
PDARule.new(1, 'b', 1, 'a',['b', 'a']),
PDARule.new(1, 'b', 1, 'b',['b', 'b']),
PDARule.new(1, nil, 2, '$',['$']),
PDARule.new(1, nil, 2, 'a',['a']),
PDARule.new(1, nil, 2, 'b',['b']),
PDARule.new(2, 'a', 2, 'a',[]),
PDARule.new(2, 'b', 2, 'b',[]),
PDARule.new(2, nil, 3, '$',['$'])
])
configuration = PDAConfiguration.new(1, Stack.new(['$']))
npda = NPDA.new(Set[configuration], [3], rulebook)
npda.accepting?
npda.current_configurations
npda.read_string('abb'); npda.accepting?
npda.current_configurations
npda.read_character('a'); npda.accepting?
npda.current_configurations

class NPDADesign < Struct.new(:start_state, :bottom_character,
                              :accept_states, :rulebook)
  def accepts?(string)
    to_npda.tap { |npda| npda.read_string(string) }.accepting?
  end
  def to_npda
    start_stack = Stack.new([bottom_character])
    start_configuration = PDAConfiguration.new(start_state, start_stack)
    NPDA.new(Set[start_configuration], accept_states, rulebook)
  end
end
npda_design = NPDADesign.new(1, '$', [3], rulebook)
npda_design.accepts?('abba')
npda_design.accepts?('babbaabbab')

class LexicalAnalyzer < Struct.new(:string)
  GRAMMAR = [
      { token: 'i', pattern: /if/  },
  { token: 'e', pattern: /else/     },
  { token: 'w', pattern: /while/     },
  { token: 'd', pattern: /do-nothing/},
  { token: '(', pattern: /\(/         },
  { token: ')', pattern: /\)/          } ,
  { token: '{', pattern: /\{/           }  ,
  { token: '}', pattern: /\}/            }  ,
  { token: ';', pattern: /;/              }  ,
  { token: '=', pattern: /=/               }  ,
  { token: '+', pattern: /\+/               }  ,
  { token: '*', pattern: /\*/                }  ,
  { token: '<', pattern: /</                  }  ,
  { token: 'n', pattern: /[0-9]+/              }  ,
  { token: 'b', pattern: /true|false/},
  { token: 'v', pattern: /[a-z]+/}
  ]
  def analyze
    [].tap do |tokens|
      while more_tokens?
        tokens.push(next_token)
      end
    end
  end
  def more_tokens?
    !string.empty?
  end

  def next_token
    rule, match = rule_matching(string)
    self.string = string_after(match)
    rule[:token]
  end
  def rule_matching(string)
    matches = GRAMMAR.map { |rule| match_at_beginning(rule[:pattern], string) }
    rules_with_matches = GRAMMAR.zip(matches).reject { |rule, match| match.nil? }
    rule_with_longest_match(rules_with_matches)
  end

  def match_at_beginning(pattern, string)
    /\A#{pattern}/.match(string)
  end

  def rule_with_longest_match(rules_with_matches)
    rules_with_matches.max_by { |rule, match| match.to_s.length }
  end
  def string_after(match)
    match.post_match.lstrip
  end
end

LexicalAnalyzer.new('y = x * 7').analyze

start_rule = PDARule.new(1, nil, 2, '$', ['S', '$'])
symbol_rules = [
    # <statement> ::= <while> | <assign>
    PDARule.new(2, nil, 2, 'S', ['W']),
    PDARule.new(2, nil, 2, 'S', ['A']),
    # <while> ::= 'w' '(' <expression> ')' '{' <statement> '}'
    PDARule.new(2, nil, 2, 'W', ['w', '(', 'E', ')', '{', 'S', '}']),
    # <assign> ::= 'v' '=' <expression>
    PDARule.new(2, nil, 2, 'A', ['v', '=', 'E']),
    # <expression> ::= <less-than>
    PDARule.new(2, nil, 2, 'E', ['L']),
    # <less-than> ::= <multiply> '<' <less-than> | <multiply>
    PDARule.new(2, nil, 2, 'L', ['M', '<', 'L']),
    PDARule.new(2, nil, 2, 'L', ['M']),
    # <multiply> ::= <term> '*' <multiply> | <term>
    PDARule.new(2, nil, 2, 'M', ['T', '*', 'M']),
    PDARule.new(2, nil, 2, 'M', ['T']),
    # <term> ::= 'n' | 'v'
    PDARule.new(2, nil, 2, 'T', ['n']),
    PDARule.new(2, nil, 2, 'T', ['v'])
]

token_rules = LexicalAnalyzer::GRAMMAR.map do |rule|
  PDARule.new(2, rule[:token], 2, rule[:token], [])
end

stop_rule = PDARule.new(2, nil, 3, '$', ['$'])

rulebook = NPDARulebook.new([start_rule, stop_rule] + symbol_rules + token_rules)

npda_design = NPDADesign.new(1, '$', [3], rulebook)

token_string = LexicalAnalyzer.new('while (x < 5) { x = x * 3 }').analyze.join

npda_design.accepts?(token_string)
