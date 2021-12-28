cmds = []
with open("input.txt") as f:
    for l in f.readlines():
        data = l.rstrip('\n').split(' ')
        cmds.append(data)

INSTRUCTION = {
        'add': lambda x,y: x + y,
        'mul': lambda x,y: x * y,
        'div': lambda x,y: x // y,
        'mod': lambda x,y: x % y,
        'eql': lambda x,y: 1 if x == y else 0,
        }

class Arg(object):
    def __init__(self, r):
        self.r = r

class Input(Arg):
    def __init__(self, n):
        Arg.__init__(self, [1, 2, 3, 4, 5, 6, 7, 8, 9])
        self.n = n

    def __str__(self):
        return f"I{self.n}"

class Value(Arg):
    def __init__(self, v):
        Arg.__init__(self, [v])
        self.v = v

    def __str__(self):
        return f"{self.v}"

class Formula(Arg):
    def __init__(self, i, a, b):
        Arg.__init__(self, calc_range(i, a, b))
        self.i = i
        self.a = a
        self.b = b

    def __str__(self):
        return f"({self.a} {self.i} {self.b})"

def calc_range(i, a, b):
    func = INSTRUCTION[i]

    result = set([])

    if (len(a.r) * len(b.r)) < 200000:
        for x in a.r:
            for y in b.r:
                result.add(func(x, y))

    return list(result)

state = {
        'ic': 0,
        'var': {
            'x': Value(0),
            'y': Value(0),
            'z': Value(0),
            'w': Value(0),
            }
        }

def resolveFormula(i, a, b):
    if i == 'add':
        if len(a.r) == 1 and a.r[0] == 0:
            return b
        if len(b.r) == 1 and b.r[0] == 0:
            return a
    if i == 'mul':
        if len(a.r) == 1 and a.r[0] == 0:
            return Value(0)
        if len(b.r) == 1 and b.r[0] == 0:
            return Value(0)
        if len(a.r) == 1 and a.r[0] == 1:
            return b
        if len(b.r) == 1 and b.r[0] == 1:
            return a
    if i == 'div':
        if len(b.r) == 1 and b.r[0] == 1:
            return a
        if len(a.r) == 1 and a.r[0] == 0:
            return Value(0)

        if isinstance(a, Formula) and isinstance(b, Value) and a.i == 'add':
            if isinstance(a.a, Formula) and a.a.i == 'mul' and isinstance(a.a.b, Value) and a.a.b.v == b.v:
                if len(a.b.r) > 0 and max(a.b.r) < b.v:
                    return a.a.a
    if i == 'mod':
        if isinstance(a, Formula) and isinstance(b, Value) and a.i == 'add':
            if isinstance(a.a, Formula) and a.a.i == 'mul' and isinstance(a.a.b, Value) and a.a.b.v == b.v:
                if len(a.b.r) > 0 and max(a.b.r) < b.v:
                    return a.b
                return Formula(i, a.b, b)

        if len(a.r) > 0 and max(a.r) < b.v:
                return a
    return Formula(i, a, b)

def print_state():
    for k in state['var']:
        v = state['var'][k]
        if (len(v.r) < 100):
            print(f"{k} = {v} {v.r}")
        else:
            print(f"{k} = {v}")

def calc(cmds, nums):
    input_vals = list(map(int, nums))
    inc = 0
    var = {
            'x': 0,
            'y': 0,
            'z': 0,
            'w': 0,
            }
    for cmd in cmds: 
        if cmd[0] == 'inp':
            var[cmd[1]] = input_vals[inc]
            inc += 1
        else:
            if (cmd[2] in var):
                p = var[cmd[2]]
            else:
                p = int(cmd[2])

            var[cmd[1]] =  INSTRUCTION[cmd[0]](var[cmd[1]], p)


    print(f"Z={var['z']}")

def solve(cmds,vals):
    lim = 1000
    for cmd in cmds:
        i = cmd[0]
        if i == 'inp':
            if state['ic'] in vals:
                state['var'][cmd[1]] = Value(vals[state['ic']])
            else:
                state['var'][cmd[1]] = Input(state['ic'])
            state['ic'] += 1
        else:
            if (cmd[2] in state['var']):
                p = state['var'][cmd[2]]
            else:
                p = Value(int(cmd[2]))
            r = calc_range(i, state['var'][cmd[1]], p)
            if len(r) == 1:
                res = Value(r[0])
            else:
                res = resolveFormula(i, state['var'][cmd[1]], p)
            state['var'][cmd[1]] = res

        print(f"---- {' '.join(cmd)}")
        print_state()

        if lim == 0:
            break;
        lim -= 1;

# solve(cmds, vals={0: 9, 1: 9, 2: 9, 3: 9, 4: 9, 5: 9, 6: 9, 7: 9, 8: 9, 9: 9, 10: 9, 11:9, 12:9, 13:9, 14:9})
# solve(cmds, vals={ 0: 1, 3: 1, 4: 1, 5: 1, 6: 5, 7: 1, 8: 1, 9: 3, 10: 9, })
solve(cmds, vals={ 0: 1, 1: 3, 2: 1, 3: 6, 4: 1, 5: 1, 6: 5, 7: 1, 8: 1, 9: 3, 10: 9, 11: 6, 12: 1, 13: 7})
# calc(cmds, '39494195799979')
calc(cmds, '13161151139617')
#i3-5=i4
#i6-4=i7
#i8+2=i9
#i5+8=i10
#i2+5=i11
#i1-2=i12
#i0+6=i13
