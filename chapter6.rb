ZERO = -> p { -> x {  x    }}
ONE = -> p { -> x {   p[x] }}
TWO = -> p { -> x { p[p[x]] }}
THREE = -> p { -> x { p[p[p[x]]] } }
FIVE = -> p { -> x { p[p[p[p[p[x]]]]] } }
FIFTEEN = -> p { -> x { p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[x]]]]]]]]]]]]]]] } }
HUNDRED = -> p { -> x { p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[
p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[
p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[x]]]]]]]]]]]]]]]]]]]]]]]]]]]
]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]] } }

TRUE =  -> x { -> y { x } }
FALSE = -> x { -> y { y } }
IF =
    -> b {
      -> x { -> y {
        b[x][y] }
    }
}

IS_ZERO = -> n { n[-> x { FALSE }][TRUE] }

PAIR =->x{->y{->f{f[x][y]}}}
LEFT =->p{p[->x{->y{x}}]}
RIGHT = -> p { p[-> x { -> y { y } } ] }

INCREMENT = -> n { -> p { -> x { p[n[p][x]] } } }

SLIDE = -> p { PAIR[RIGHT[p]][INCREMENT[RIGHT[p]]] }
DECREMENT = -> n { LEFT[n[SLIDE][PAIR[ZERO][ZERO]]] }

ADD = -> m { -> n { n[INCREMENT][m] } }
SUBTRACT = -> m { -> n { n[DECREMENT][m] } }
MULTIPLY = -> m { -> n { n[ADD[m]][ZERO] } }
POWER = -> m { -> n { n[MULTIPLY[m]][ONE] } }

IS_LESS_OR_EQUAL = -> m { -> n {
  IS_ZERO[SUBTRACT[m][n]] }}

def mod(m, n)
  IF[IS_LESS_OR_EQUAL[n][m]][
    mod(SUBTRACT[m][n], n)
][
    m
]
end

MOD =
    -> m { -> n {
      IF[IS_LESS_OR_EQUAL[n][m]][ MOD[SUBTRACT[m][n]][n]
      ][
          m
      ]
    }}

MOD =
    -> m { -> n {
      IF[IS_LESS_OR_EQUAL[n][m]][ -> x {
        MOD[SUBTRACT[m][n]][n][x] }
      ][
          m
      ]
    }}

Y = -> f { -> x { f[x[x]] }[-> x { f[x[x]] }] }

Z = -> f { -> x { f[-> y { x[x][y] }] }[-> x { f[-> y { x[x][y] }] }] }

MOD =
    Z[-> f { -> m { -> n {
      IF[IS_LESS_OR_EQUAL[n][m]][ -> x {
        f[SUBTRACT[m][n]][n][x] }
      ][
          m
      ]
    } } }]

def to_integer(proc)
  proc[-> n { n + 1 }][0]
end

def to_boolean(proc)
  proc[true][false]
end

def if(proc, x, y)
  proc[x][y]
end

to_boolean(TRUE)# => true
to_boolean(FALSE)# => false

to_integer(DECREMENT[FIVE])
to_integer(MOD[
               POWER[THREE][THREE]
           ][ ADD[THREE][TWO]
           ])


EMPTY = PAIR[TRUE][TRUE]
UNSHIFT = -> l { -> x {
  PAIR[FALSE][PAIR[x][l]] }}
IS_EMPTY = LEFT
FIRST = -> l { LEFT[RIGHT[l]] }
REST = -> l { RIGHT[RIGHT[l]] }
my_list = UNSHIFT[
    UNSHIFT[ UNSHIFT[EMPTY][THREE]
    ][TWO] ][ONE]
to_integer(FIRST[my_list])


def to_array(proc)
  array = []
  until to_boolean(IS_EMPTY[proc])
    array.push(FIRST[proc])
    proc = REST[proc]
  end
  array
end
to_array(my_list)


RANGE = Z[-> f {
  -> m { -> n { IF[IS_LESS_OR_EQUAL[m][n]][
      -> x {
        UNSHIFT[f[INCREMENT[m]][n]][m][x] }
  ][
      EMPTY
  ]
  }} }]

FOLD = Z[-> f {
  -> l { -> x { -> g { IF[IS_EMPTY[l]][
      x
  ][
      -> y {
        g[f[REST[l]][x][g]][FIRST[l]][y] }
  ]
  }}} }]

to_integer(FOLD[RANGE[ONE][FIVE]][ZERO][ADD])

MAP =
    -> k { -> f {
      FOLD[k][EMPTY][
          -> l { -> x { UNSHIFT[l][f[x]] } } ]
    }}

my_list = MAP[RANGE[ONE][FIVE]][INCREMENT]
to_array(my_list).map { |p| to_integer(p) }

TEN = MULTIPLY[TWO][FIVE]
B =TEN
F = INCREMENT[B]
I = INCREMENT[F]
U = INCREMENT[I]
ZED = INCREMENT[U]

FIZZ = UNSHIFT[UNSHIFT[UNSHIFT[UNSHIFT[EMPTY][ZED]][ZED]][I]][F]
BUZZ = UNSHIFT[UNSHIFT[UNSHIFT[UNSHIFT[EMPTY][ZED]][ZED]][U]][B]
FIZZBUZZ = UNSHIFT[UNSHIFT[UNSHIFT[UNSHIFT[BUZZ][ZED]][ZED]][I]][F]


def to_char(c)
  '0123456789BFiuz'.slice(to_integer(c))
end
def to_string(s)
  to_array(s).map { |c| to_char(c) }.join
end

to_char(ZED)
to_string(FIZZBUZZ)


MAP[RANGE[ONE][HUNDRED]][-> n { IF[IS_ZERO[MOD[n][FIFTEEN]]][
    FIZZBUZZ
][IF[IS_ZERO[MOD[n][THREE]]][ FIZZ
                                  ][IF[IS_ZERO[MOD[n][FIVE]]][
                                        BUZZ
                                    ][ n.to_s
                                  ]]] }]

def to_digits(n)
  previous_digits =
  if n < 10
    []
  else
    to_digits(n / 10)
  end
  previous_digits.push(n % 10)
end

DIV =
    Z[-> f { -> m { -> n {
      IF[IS_LESS_OR_EQUAL[n][m]][ -> x {
        INCREMENT[f[SUBTRACT[m][n]][n]][x] }
      ][
          ZERO
      ]
    } } }]
PUSH = -> l {
  -> x {
    FOLD[l][UNSHIFT[EMPTY][x]][UNSHIFT] }
}


TO_DIGITS =
    Z[-> f { -> n { PUSH[
        IF[IS_LESS_OR_EQUAL[n][DECREMENT[TEN]]][
            EMPTY
        ][
            -> x {
              f[DIV[n][TEN]][x] }
        ]
    ][MOD[n][TEN]] } }]
to_array(TO_DIGITS[FIVE]).map { |p| to_integer(p) }
to_array(TO_DIGITS[POWER[FIVE][THREE]]).map { |p| to_integer(p) }


solution = MAP[RANGE[ONE][HUNDRED]][-> n {
  IF[IS_ZERO[MOD[n][FIFTEEN]]][ FIZZBUZZ
  ][IF[IS_ZERO[MOD[n][THREE]]][ FIZZ
    ][IF[IS_ZERO[MOD[n][FIVE]]][
          BUZZ
      ][ TO_DIGITS[n]
      ]]] }]

to_array(solution).each do |p|
  puts to_string(p)
end; nil


ZEROS = Z[-> f { UNSHIFT[f][ZERO] }]

to_integer(FIRST[ZEROS])

def to_array(l, count = nil) array = []
  until to_boolean(IS_EMPTY[l]) || count == 0
  array.push(FIRST[l])
  l = REST[l]
  count = count - 1 unless count.nil?
  end
  array
end

to_array(ZEROS, 5).map { |p| to_integer(p) }

UPWARDS_OF = Z[-> f { -> n { UNSHIFT[-> x { f[INCREMENT[n]][x] }][n] } }]
to_array(UPWARDS_OF[ZERO], 5).map { |p| to_integer(p) }

MULTIPLES_OF = -> m {
  Z[-> f {
    -> n { UNSHIFT[-> x { f[ADD[m][n]][x] }][n] }
  }][m] }

to_array(MULTIPLES_OF[TWO], 10).map { |p| to_integer(p) }


class LCVariable < Struct.new(:name)
  def to_s
    name.to_s
  end
  def inspect
    to_s
  end
end

class LCFunction < Struct.new(:parameter, :body)
  def to_s
    "-> #{parameter} { #{body} }"
  end
  def inspect
    to_s
  end
end

class LCCall < Struct.new(:left, :right)
  def to_s
    "#{left}[#{right}]"
  end
  def inspect
    to_s
  end
end


one = LCFunction.new(:p,
                     LCFunction.new(:x,
                                    LCCall.new(LCVariable.new(:p), LCVariable.new(:x)) )
)

increment = LCFunction.new(:n,
                           LCFunction.new(:p, LCFunction.new(:x,
                                                             LCCall.new(LCVariable.new(:p), LCCall.new(
                                                                 LCCall.new(LCVariable.new(:n), LCVariable.new(:p)),
                                                                 LCVariable.new(:x))
                                                             ))
                           ))

add = LCFunction.new(:m,
                     LCFunction.new(:n,
                                    LCCall.new(LCCall.new(LCVariable.new(:n), increment), LCVariable.new(:m)) )
)


class LCVariable
  def replace(name, replacement)
    if self.name == name
      replacement
    else
      self
    end
  end
end
class LCFunction
  def replace(name, replacement)
    if parameter == name
      self
    else
      LCFunction.new(parameter, body.replace(name, replacement))
    end
  end
end
class LCCall
  def replace(name, replacement)
    LCCall.new(left.replace(name, replacement), right.replace(name, replacement))
  end
end

expression = LCVariable.new(:x)
expression.replace(:x, LCFunction.new(:y, LCVariable.new(:y)))
expression.replace(:z, LCFunction.new(:y, LCVariable.new(:y)))


expression =
    LCCall.new( LCCall.new(
                    LCCall.new( LCVariable.new(:a),
                                LCVariable.new(:b) ),
                    LCVariable.new(:c) ),
                LCVariable.new(:b) )
expression.to_s
expression = expression.replace(:a, LCVariable.new(:x))
expression.to_s

expression = expression.replace(:b, LCFunction.new(:x, LCVariable.new(:x)))
expression.to_s


class LCFunction
  def call(argument)
    body.replace(parameter, argument)
  end
end

function = LCFunction.new(:x,
                          LCFunction.new(:y,
                                         LCCall.new(LCVariable.new(:x), LCVariable.new(:y)) )
)
#=> -> x { -> y { x[y] } }
argument = LCFunction.new(:z, LCVariable.new(:z))# => -> z { z }
function.call(argument)
#=> -> y { -> z { z }[y] }


class LCVariable
  def callable?
  false
end end
class LCFunction
  def callable?
  true
end end
class LCCall
  def callable?
  false
end end

class LCVariable
  def reducible?
    false
  end
end
class LCFunction
  def reducible?
    false
  end
end
class LCCall
  def reducible?
    left.reducible? || right.reducible? || left.callable?
  end

  def reduce
    if left.reducible?
      LCCall.new(left.reduce, right)
    elsif right.reducible?
      LCCall.new(left, right.reduce)
    else
      left.call(right)
    end
  end
end

expression = LCCall.new(LCCall.new(add, one), one)

while expression.reducible?
     puts expression
     expression = expression.reduce
end; puts expression

require 'treetop'
Treetop.load('lambda_calculus')
parse_tree = LambdaCalculusParser.new.parse('-> x { x[x] }[-> y { y }]')
expression = parse_tree.to_ast
expression.reduce
