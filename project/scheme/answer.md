# Scheme Interpreter
## Part I: The Reader
### Problem 01
> 实现函数*scheme_read*、*read_tail*  
> In short, scheme_read returns the next single complete expression in the buffer and read_tail returns the rest of a list or pair in the buffer.

下面是对该问题的引导。

> scheme_read:  
> * If the current token is the string "nil", return the nil object.
> * If the current token is (, the expression is a pair or list. Call read_tail on the rest of src and return its result.
> * If the current token is ', the rest of the buffer should be processed as a quote expression. You don't have to worry about this until Problem 6.
> * If the next token is not a delimiter, then it must be a primitive expression (i.e. a number, boolean). Return it. Provided
> * If none of the above cases apply, raise an error. Provided

完整代码将在Problem 06处给出.

> read_tail:
> * If there are no more tokens, then the list is missing a close parenthesis and we should raise an error. Provided
> * If the token is ), then we've reached the end of the list or pair. Remove this token from the buffer and return the nil object.
> * If none of the above cases apply, the next token is the operator in a combination. For example, src could contain + 2 3). To parse this:
>     1. scheme_read the next complete expression in the buffer.
>     2. Call read_tail to read the rest of the combination until the matching closing parenthesis.
>     3. Return the results as a Pair instance, where the first element is the next complete expression from (1) and the second element is the rest of the combination from (2).
```python
def read_tail(src):
    try:
        if src.current() is None:
            raise SyntaxError('unexpected end of file')
        elif src.current() == ')':
            # BEGIN PROBLEM 1
            "*** YOUR CODE HERE ***"
            src.pop_first()
            return nil
            # END PROBLEM 1
        elif src.current() == '.':
            src.pop_first()
            expr = scheme_read(src)
            if src.current() is None:
                raise SyntaxError('unexpected end of file')
            if src.pop_first() != ')':
                raise SyntaxError('expected one element after .')
            return expr
        else:
            # BEGIN PROBLEM 1
            "*** YOUR CODE HERE ***"
            first = scheme_read(src)
            rest = read_tail(src)
            return Pair(first, rest)
            # END PROBLEM 1
    except EOFError:
        raise SyntaxError('unexpected end of file')
```
## Part II: The Evaluator
### Problem 02

> 实现`Frame`类的*define*和*lookup*方法

`Frame`类有两个实例属性:    
* *bindings*字典, 把环境中的变量名映射成值    
* *parent*是该*Frame*的父*Frame*.(Global Frame的*parent*为*None*)

*define*就是向字典中增加*pair(symbol, value)*.
```python
def define(self, symbol, value):
    # BEGIN PROBLEM 2
    "*** YOUR CODE HERE ***"
    self.bindings[symbol] = value
    # END PROBLEM 2
```
*lookup*就是在字典中查找*symbol*.如果本*Frame*中未找到, 且有父*Frame*, 就向上查找.
```python
def lookup(self, symbol):
    # BEGIN PROBLEM 2
    "*** YOUR CODE HERE ***"
    if symbol in self.bindings:
        return self.bindings[symbol]
    if self.parent:
        return self.parent.lookup(symbol)
    # END PROBLEM 2
    raise SchemeError('unknown identifier: {0}'.format(symbol))
```
### Problem 03
> 完善`BuiltinProcedure`类的*apply*方法

`BuiltinProcedure`类有两个实例属性:    
* *fn*, 实现Scheme内置方法的Python函数.
* *use_env*, 一个布尔值, 用来说明是否需要当前环境作为最后一个参数传入.

下面是对问题的引导:
> * Convert the Scheme list to a Python list of arguments. Hint: args is a Pair, which has a .first and .rest similar to a Linked List. Think about how you would put the values of a Linked List into a list.
> * If self.use_env is True, then add the current environment env as the last argument to this Python list.
> * Call self.fn on all of those arguments using *args notation (f(1, 2, 3) is equivalent to f(*[1, 2, 3])) Provided
> * If calling the function results in a TypeError exception being raised, then the wrong number of arguments were passed. Use a try/except block to intercept the exception and raise an appropriate SchemeError in its place. Provided

主要在于如何将Scheme的list转换成Python的list.
```python
def apply(self, args, env):
    if not scheme_listp(args):
        raise SchemeError('arguments are not in a list: {0}'.format(args))
    # Convert a Scheme list to a Python list
    arguments_list = []
    # BEGIN PROBLEM 3
    "*** YOUR CODE HERE ***"
    while args is not nil:
        arguments_list.append(args.first)
        args = args.rest
    if self.use_env:
        arguments_list.append(env)
    # END PROBLEM 3
    try:
        return self.fn(*arguments_list)
    except TypeError as err:
        raise SchemeError('incorrect number of arguments: {0}'.format(self))
```

### Problem 04
> 完善*scheme_eval*

下面是对问题的引导:    
> 1. Evaluate the operator (which should evaluate to an instance of Procedure)
> 2. Evaluate all of the operands
> 3. Apply the procedure on the evaluated operands, and return the result

前两步需要递归调用*scheme_eval*.还有一些其他应该用到的函数,如下:    
> * The validate_procedure function raises an error if the provided argument is not a Scheme procedure. 用于检查operator是否合法.
> * The map method of Pair returns a new Scheme list constructed by applying a one-argument function to every item in a Scheme list.用于获得代表operands的Scheme list.
> * The scheme_apply function applies a Scheme procedure to a Scheme list of arguments.用于向operands调用operator

`expr.first`是*operator*, `expr.rest`是*operands*.
```python
def scheme_eval(expr, env, _=None):
    # Evaluate atoms
    if scheme_symbolp(expr):
        return env.lookup(expr)
    elif self_evaluating(expr):
        return expr
    # All non-atomic expressions are lists (combinations)
    if not scheme_listp(expr):
        raise SchemeError('malformed list: {0}'.format(repl_str(expr)))
    first, rest = expr.first, expr.rest
    if scheme_symbolp(first) and first in SPECIAL_FORMS:
        return SPECIAL_FORMS[first](rest, env)
    else:
        # BEGIN PROBLEM 4
        "*** YOUR CODE HERE ***"
        operator = scheme_eval(first, env)
        validate_procedure(operator)
        operands = rest.map(lambda expr: scheme_eval(expr, env))
        return scheme_apply(operator, operands, env)
        # END PROBLEM 4
```
### Problem 05
> 完善*do_define_form*的第一部分

简要思路就是用之前实现的`Frame`的类方法*define*.所以需要*symbol*和*value*.`expressions.first`就是*symbol*即*target*. 而*value*由于可能是表达式形式,所以需要调用*scheme_eval*函数. 传入的参数是`expressions.rest.first`, 最开始以为应该传入`expressions.rest`, 结果一直在报错.    
由于Problem 09还会完善这一部分,所以后面再贴代码.

### Problem 06
> 实现*quote*功能

实现分为两部分.
* *do_quote_form*:返回传入的`expressions.first`即可.(`expressions.rest`中是不为*quote*的部分)
```python
def do_quote_form(expressions, env):
    validate_form(expressions, 1, 1)
    # BEGIN PROBLEM 6
    "*** YOUR CODE HERE ***"
    return expressions.first
    # END PROBLEM 6
```
* *scheme_read*:将类似`'bagel`的形式转换成`Pair('quote', Pair('bagel', nil))`的形式.
```python
def scheme_read(src):
    if src.current() is None:
        raise EOFError
    val = src.pop_first() # Get and remove the first token
    if val == 'nil':
        # BEGIN PROBLEM 1
        "*** YOUR CODE HERE ***"
        return nil
        # END PROBLEM 1
    elif val == '(':
        # BEGIN PROBLEM 1
        "*** YOUR CODE HERE ***"
        return read_tail(src)
        # END PROBLEM 1
    elif val == "'":
        # BEGIN PROBLEM 6
        "*** YOUR CODE HERE ***"
        return Pair('quote', Pair(scheme_read(src), nil))
        # END PROBLEM 6
    elif val not in DELIMITERS:
        return val
    else:
        raise SyntaxError('unexpected token: {0}'.format(val))
```
### Problem 07
> 修改*eval_all*

该函数主要作用于*begin*语法,即从左向右执行,返回最右表达式.当*begin*内list为空时,应该返回*None*.故使用迭代即可.
```python
def eval_all(expressions, env):
    # BEGIN PROBLEM 7
    ret = None
    while expressions is not nil:
        ret = scheme_eval(expressions.first, env)
        expressions = expressions.rest
    return ret
    # END PROBLEM 7
```
### User-Defined Procedures

即`LambdaProcedure`实例.有三个实例属性:    
* formals:形参列表, a Scheme list.
* body:函数体, a Scheme list.
* env:定义时的环境.

### Problem 08

> 实现*do_lambda_form*

只需要定义`LambdaProcedure`返回.

```python
def do_lambda_form(expressions, env):
    validate_form(expressions, 2)
    formals = expressions.first
    validate_formals(formals)
    # BEGIN PROBLEM 8
    "*** YOUR CODE HERE ***"
    return LambdaProcedure(expressions.first, expressions.rest, env)
    # END PROBLEM 8
```

### Problem 09
> 完善*do_define_form*的第二部分

本题的引导如下:     
> * Using the given variables target and expressions, find the defined function's name, formals, and body.
> * Create a LambdaProcedure instance using the formals and body. Hint: You can use what you've done in Problem 8 and call do_lambda_form on the appropriate arguments
> * Bind the name to the LambdaProcedure instance

很容易得到函数的*name*, *formals*, *body*.之后通过前面实现的*do_lambda_form*即可将返回的*lambda*绑定到*env*中.
```python
def do_define_form(expressions, env):
    validate_form(expressions, 2)  # Checks that expressions is a list of length at least 2
    target = expressions.first
    if scheme_symbolp(target):
        validate_form(expressions, 2, 2)  # Checks that expressions is a list of length exactly 2
        # BEGIN PROBLEM 5
        "*** YOUR CODE HERE ***"
        value = scheme_eval(expressions.rest.first, env)
        env.define(target, value)
        return target
        # END PROBLEM 5
    elif isinstance(target, Pair) and scheme_symbolp(target.first):
        # BEGIN PROBLEM 9
        "*** YOUR CODE HERE ***"
        name, formals, body = target.first, target.rest, expressions.rest
        env.define(name, do_lambda_form(Pair(formals, body), env))
        return name
        # END PROBLEM 9
    else:
        bad_target = target.first if isinstance(target, Pair) else target
        raise SchemeError('non-symbol: {0}'.format(bad_target))
```
### Problem 10
> 实现make_child_frame

本题的引导如下:
> * If the number of argument values does not match with the number of formal parameters, raise a SchemeError. Provided
> * Create a new Frame instance, the parent of which is self.
> * Bind each formal parameter to its corresponding argument value in the newly created frame. The first symbol in formals should be bound to the first value in vals, and so on.
> * Return the new frame.

先检查形参与实参的个数是否相等.然后创建一个新的`Frame`实例, *parent*属性为*self*.在新环境中迭代把每个实参绑定到形参上.最后返回新环境.
```python
def make_child_frame(self, formals, vals):
    if len(formals) != len(vals):
        raise SchemeError('Incorrect number of arguments to function call')
    # BEGIN PROBLEM 10
    "*** YOUR CODE HERE ***"
    new_env = Frame(self)
    while formals is not nil:
        new_env.define(formals.first, vals.first)
        formals, vals = formals.rest, vals.rest
    return new_env
    # END PROBLEM 10
```

### Problem 11
> 实现`LambdaProcedure`类中的*make_call_frame*

将`LambdaProcedure`类中的*formals*和参数*args*传入`self.env`的*make_child_env*即可.
```python
def make_call_frame(self, args, env):
    # BEGIN PROBLEM 11
    "*** YOUR CODE HERE ***"
    return self.env.make_child_frame(self.formals, args)
    # END PROBLEM 11
```

### Problem 12
> 实现*do_and_form*和*do_or_form*

对于and, 从左到右对每个*expression*调用*scheme_eval*, 如果有False, 返回#f. 否则返回最后一个*expression*的值. 如果expressions为空, 则结果为#t.
```python
def do_and_form(expressions, env):
    # BEGIN PROBLEM 12
    "*** YOUR CODE HERE ***"
    val = True
    while expressions is not nil:
        val = scheme_eval(expressions.first, env)
        if is_false_primitive(val):
            return False
        expressions = expressions.rest
    return val
    # END PROBLEM 12
```
对于or, 从左到右每个*expression*调用*scheme_eval*, 如果有不为False的值, 返回该值. 否则返回#f. 如果expressions为空, 则结果为#f.
```python
def do_or_form(expressions, env):
    # BEGIN PROBLEM 12
    "*** YOUR CODE HERE ***"
    val = False
    while expressions is not nil and is_false_primitive(val):
        val = scheme_eval(expressions.first, env)
        expressions = expressions.rest
    return val
    # END PROBLEM 12
```

### Problem 13
> 完善do_cond_form

*clause*即为Pair(条件, 结果).故只需要在条件为True时,对结果调用eval_all并返回即可.又由于有可能没有结果存在,需要进行额外判断.
```python
def do_cond_form(expressions, env):
    while expressions is not nil:
        clause = expressions.first
        validate_form(clause, 1)
        if clause.first == 'else':
            test = True
            if expressions.rest != nil:
                raise SchemeError('else must be last')
        else:
            test = scheme_eval(clause.first, env)
        if is_true_primitive(test):
            # BEGIN PROBLEM 13
            "*** YOUR CODE HERE ***"
            return eval_all(clause.rest, env) if clause.rest is not nil else test
            # END PROBLEM 13
        expressions = expressions.rest
```

### Problem 14
> 实现*make_let_frame*

> let语法为:`(let ([binding] ...) <body> ...)`  
> 每个binding形式为:`(<name> <expression>)`   
> * First, the expression of each binding is evaluated in the current frame. 
> * Next, a new frame that extends the current environment is created and each name is bound to its corresponding evaluated expression in it.    
> * Finally the body expressions are evaluated in order, returning the evaluated last one.    

遍历*bindings*, 每个*binding*为*Pair(name, expression)*. 最后要调用*make_child_frame*, 需要传入两个*Pair list*, 所以在遍历过程中建立*names*和*values*.用*validate_form*来保证*expression*的*len*为1. 用*validate_formals*来保证*names*中没有重名.
```python
def make_let_frame(bindings, env):
    if not scheme_listp(bindings):
        raise SchemeError('bad bindings list in let form')
    names = values = nil
    # BEGIN PROBLEM 14
    "*** YOUR CODE HERE ***"
    while bindings is not nil:
        binding = bindings.first
        validate_form(binding.rest, 1, 1)
        name, value = binding.first, scheme_eval(binding.rest.first, env)
        names, values = Pair(name, names), Pair(value, values)
        bindings = bindings.rest
    # END PROBLEM 14
    validate_formals(names)
    return env.make_child_frame(names, values)
```
## Part III: Write Some Scheme
### Problem 15

> 实现*enumerate*

> takes in a list of values and returns a list of two-element lists, where the first element is the index of the value, and the second element is the value itself.

直接看例子比较好理解这个函数的作用.
```scheme
scm> (enumerate '(3 4 5 6))
((0 3) (1 4) (2 5) (3 6))
scm> (enumerate '())
()
```
按照课上讲的思路递归实现即可.
```scheme
(define (enumerate s)
  ; BEGIN PROBLEM 15
  (define (func i s)
    (cond
      ((null? s) nil)
      (else (cons (list i (car s)) (func (+ i 1) (cdr s))))))
  (func 0 s)
  )
  ; END PROBLEM 15
```

### Problem 16
> 实现*merge*

对输入的两个list根据comp来比较,整合成一个list并返回.同样看例子来理解函数作用.
```scheme
scm> (merge < '(1 4 6) '(2 5 8))
(1 2 4 5 6 8)
scm> (merge > '(6 4 1) '(8 5 2))
(8 6 5 4 2 1)
```
同样递归实现.分情况:
* list1和list2都为nil,返回nil;
* list1为nil,返回list2;
* list2为nil,返回list1;
* 否则按comp比较并递归.
```scheme
(define (merge comp list1 list2)
  ; BEGIN PROBLEM 16
  (define (func list1 list2)
    (cond
      ((and (null? list1) (null? list2)) nil)
      ((null? list1) list2)
      ((null? list2) list1)
      ((comp (car list1) (car list2)) (cons (car list1) (func (cdr list1) list2)))
      (else (cons (car list2) (func list1 (cdr list2))))
      )
    )
  (func list1 list2)
  )
  ; END PROBLEM 16
```
### Problem 17
这个题好难...   
> 完善*let-to-lambda*

看函数名很容易理解:将let形式转化成lambda形式.   
对输入进行分类:
```scheme
(define (let-to-lambda expr)
  (cond ((atom?   expr) <rewrite atoms>)
        ((quoted? expr) <rewrite quoted expressions>)
        ((lambda? expr) <rewrite lambda expressions>)
        ((define? expr) <rewrite define expressions>)
        ((let?    expr) <rewrite let expressions>)
        (else           <rewrite other expressions>)))
```
无从下手怎么办呢?直接运行测试,从样例出发.   
样例1:
```scheme
scm> (let-to-lambda 1)
# Error: expected
#     1
```
可以发现是*atom*类,易知直接返回*expr*即可.  
样例2:
```scheme
scm> (let-to-lambda '(+ 1 2))
# Error: expected
#     (+ 1 2)
```
看了一下老师给的分类,好像没有符合的.实验下也能发现是属于*else*.看expected感觉应该是*expr*,先这么填上.
样例3:
```scheme
scm> (let-to-lambda '(let ((a 1)
....                 (b 2))
....                (+ a b)))
# Error: expected
#     ((lambda (a b) (+ a b)) 1 2)
```
易知是*let*类.提供的代码中已经帮我们把输入处理成了*values*和*body*,在这个样例中*values*是`((a 1)(b 2))`,body是`((+ a b))`.课程的*hint1*提示用*zip*来实现.思考一下可以发现实际上结果中的`(a b)`和`(1 2)`,其实就是`(zip values)`得到的.于是我们接下来的工作就是实现*zip*.   
由于Scheme不支持迭代,个人感觉这个*zip*实现起来相当困难(也可能是我方法错了,见笑).*hint1*中还提到可能会用到内置方法*map*来实现*zip*.所以我的方法是先获取传入*pairs*中一个*pair*的大小.然后对*pairs*调用*map*,并根据递归深度生成获得*pair*中某*first*的函数.说起来有些不清楚,直接上代码.
```scheme
(define (len p)
  (if (null? p) 0 (+ 1 (len (cdr p))))
  )

(define (zip pairs)
  (define l (len (car pairs)))
  (define (func i)
    (if (= i 0) (lambda (p) p)
      (lambda (p) (cdr ((func (* i 1)) p))))
    )
  (define (recur i)
    (if (= i l) nil
      (cons (map (lambda (p) (car ((func i) p))) pairs) (recur (+ i 1))))
    )
  (recur 0)
  )
```
首先是*len*函数来获取一个Pair的大小,很容易理解就不解释了.在*zip*实现中,变量*l*代表了一个*pair*的大小;函数*func*是*map*需要的*proc*参数,会根据传入的*i*来决定返回递归多少次的函数.举个例子,*i*=0时,返回*identity*作用的*lambda*,*i*=1时返回`(cdr p)`作用的*lambda*,*i*=2时返回`(cddr p)`作用的*lambda*,*i*=3时返回`(cdr (cddr p))`作用的*lambda*...最后*recur*函数递归生成zip的结果,与python中的zip基本一致.     
有了*zip*后,*let*类就变得很好实现了.定义一个临时变量*tmp*来储存*zip*的结果,最后返回的就是`(cons (list 'lambda (car tmp) (car body)) (cadr tmp))`.      
实现了上述部分后,我们就可以通过suite1的测试了.
样例4:
```scheme
scm> (let-to-lambda '(lambda (let a b) (+ let a b)))
# Error: expected
#     (lambda (let a b) (+ let a b))
```
接下来是实现*lambda*类,注意这个样例中的*let*只是变量名,实际并没有*let*语句.注意到lambda部分中已经为我们把输入处理成了*form*, *params*和*body*.(*form*只是字符串'*lambda*'或'*define*',我最开始以为是形参)这个例子比较简单,直接返回*expr*就可以通过,所以我们先这样做从而获取更多样例.
样例5:
```scheme
scm> (let-to-lambda '(lambda (x) a (let ((a x)) a)))
# Error: expected
#     (lambda (x) a ((lambda (a) a) x))
```
可以看到在*body*中出现了*let*语句.易知*form*和*params*我们是不需要处理的.只要对*body*部分递归调用*let-to-lambda*即可.但是需要注意的是,*body*部分可以包含多条语句(就比如这个样例的*body*部分包含`a`和`(let ((a x)) a))`两条语句),所以不能只是简单的`(let-to-lambda (car body))`.怎么办对body中所有的语句调用*let-to-lambda*呢?使用*map*.所以最后返回的就是`(cons form (cons params (map let-to-lambda body)))`.      
样例6:
```scheme
scm> (let-to-lambda '(let ((a (let ((a 2)) a))
....                 (b 2))
....                (+ a b)))
# Error: expected
#     ((lambda (a b) (+ a b)) ((lambda (a) a) 2) 2)
```
这个样例说明之前的*let*没有考虑*values*可能是*expression*,就好像这个样例中对外层*let*中*a*赋的值来源于内层*let*的返回值.所以我们应该对`(cadr tmp)`调用*let-to-lambda*.同样,应该使用map.最后返回`(cons (list 'lambda (car tmp) (car body)) (map let-to-lambda (cadr tmp)))`.  
样例7:
```scheme
scm> (let-to-lambda '(let ((a 1))
....                (let ((b a))
....                     b)))
# Error: expected
#     ((lambda (a) ((lambda (b) b) a)) 1)
```
这个样例说明*let*的*body*部分也应该调用*let-to-lambda*.最后返回`(cons (list 'lambda (car tmp) (let-to-lambda (car body))) (map let-to-lambda (cadr tmp)))`.

样例8:
```scheme
scm> (let-to-lambda '(+ 1 (let ((a 1)) a)))
# Error: expected
#     (+ 1 ((lambda (a) a) 1))
```
这个样例属于*else*部分,所以我们最开始只填*expr*是错误的.当*expr*是*expression*时,我们应该对每个参与运算的表达式递归调用*let-to-lambda*,所以要用到*map*.返回`(cons (car expr) (map let-to-lambda (cdr expr)))`.      
至此,我们的代码可以通过全部的测试样例了.这个题也终于告一段落.下面给出完整代码.真的好难啊,做了好久.
```scheme
(define (let-to-lambda expr)
  (cond ((atom? expr)
         ; BEGIN PROBLEM 17
          expr
         ; END PROBLEM 17
         )
        ((quoted? expr)
         ; BEGIN PROBLEM 17
          expr
         ; END PROBLEM 17
         )
        ((or (lambda? expr)
             (define? expr))
         (let ((form   (car expr))
               (params (cadr expr))
               (body   (cddr expr)))
           ; BEGIN PROBLEM 17
           (cons form (cons params (map let-to-lambda body)))
           ; END PROBLEM 17
           ))
        ((let? expr)
         (let ((values (cadr expr))
               (body   (cddr expr)))
           ; BEGIN PROBLEM 17
           (define tmp (zip values))
           (cons (list 'lambda (car tmp) (let-to-lambda (car body))) (map let-to-lambda (cadr tmp)))
           ; END PROBLEM 17
           ))
        (else
         ; BEGIN PROBLEM 17
          (cons (car expr) (map let-to-lambda (cdr expr)))
         ; END PROBLEM 17
         )))
```

### Problem EC Mu
> 实现do_mu_form,完善MuProcedure

纸老虎...随便猜了一下然后测试就过了...不过这个动态作用域还是挺厉害的.
```scheme
class MuProcedure(Procedure):
    def __init__(self, formals, body):
        """A procedure with formal parameter list FORMALS (a Scheme list) and
        Scheme list BODY as its definition."""
        self.formals = formals
        self.body = body

    # BEGIN PROBLEM EC
    "*** YOUR CODE HERE ***"
    def make_call_frame(self, args, env):
        return env.make_child_frame(self.formals, args)
    # END PROBLEM EC

    def __str__(self):
        return str(Pair('mu', Pair(self.formals, self.body)))

    def __repr__(self):
        return 'MuProcedure({0}, {1})'.format(
            repr(self.formals), repr(self.body))

def do_mu_form(expressions, env):
    validate_form(expressions, 2)
    formals = expressions.first
    validate_formals(formals)
    # BEGIN PROBLEM EC
    "*** YOUR CODE HERE ***"
    return MuProcedure(expressions.first, expressions.rest)
    # END PROBLEM EC
```
## Part IV: Optional
### Problem 18

被选做题暴打了...

> 实现尾调用优化

尾调用就是指某个函数的最后一步是调用另一个函数.所以可以直接把环境变成要执行的函数的环境,从而不用进行递归.即为尾递归优化.        
> When scheme_optimized_eval receives a non-atomic expression in a tail context, then it returns an Unevaluated instance. Otherwise, it should repeatedly call original_scheme_eval until the result is a value, rather than an Unevaluated.

其实根据引导的意思就能够实现...
```python
def optimize_tail_calls(original_scheme_eval):
    def optimized_eval(expr, env, tail=False):
        if tail and not scheme_symbolp(expr) and not self_evaluating(expr):
            return Unevaluated(expr, env)

        result = Unevaluated(expr, env)
        # BEGIN PROBLEM 18
        while isinstance(result, Unevaluated):
            result = original_scheme_eval(result.expr, result.env)
        return result
        # END PROBLEM 18
    return optimized_eval
```
但仅仅这样是不够的,还需要把发生尾调用的地方使用的*scheme_eval*函数增加第三个参数*True*.然后我寄了.我以为只需要改*eval_all*,结果改了还是错.后来发现还需要改*do_and_form*和*do_or_form*.而且第三个参数要改成`True if expressions.rest is nil else False`.

### Problem 19

> 完善*do_define_macro*

只要借鉴*do_lambda_form*和*do_define_form*就可以了.通过*do_lambda_form*借鉴如何保证正确输入;通过*do_define_form*借鉴如何定义`MacroProcedure`.注意`MacroProcedure`是继承自`LambdaProcedure`,所以构造函数相同.最后需要更新*scheme_eval*.当遇到*macro*时要调用类方法*apply_macro*.
```python
def scheme_eval(expr, env, _=None):
    # Evaluate atoms
    if scheme_symbolp(expr):
        return env.lookup(expr)
    elif self_evaluating(expr):
        return expr

    # All non-atomic expressions are lists (combinations)
    if not scheme_listp(expr):
        raise SchemeError('malformed list: {0}'.format(repl_str(expr)))
    first, rest = expr.first, expr.rest
    if scheme_symbolp(first) and first in SPECIAL_FORMS:
        return SPECIAL_FORMS[first](rest, env)
    else:
        # BEGIN PROBLEM 4
        "*** YOUR CODE HERE ***"
        operator = scheme_eval(first, env)
        validate_procedure(operator)
        if isinstance(operator, MacroProcedure):
            return scheme_eval(operator.apply_macro(rest, env), env)
        operands = rest.map(lambda expr: scheme_eval(expr, env))
        return scheme_apply(operator, operands, env)
        # END PROBLEM 4

def do_define_macro(expressions, env):
    # BEGIN Problem 19
    "*** YOUR CODE HERE ***"
    validate_form(expressions, 2, 2)
    validate_form(expressions.first, 1)
    validate_formals(expressions.first)
    target = expressions.first
    name, formals, body = target.first, target.rest, expressions.rest
    env.define(name, MacroProcedure(formals, body, env))
    return name
    # END Problem 19
```
这个proj就算结束了.也不好说有多少收获吧hhh.代码仅供参考,不要copy哦.