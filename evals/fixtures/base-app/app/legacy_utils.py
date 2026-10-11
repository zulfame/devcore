def f(x,y):
  a=x
  b=y
  if a>b:
    return a
  else:
    return b
def g(l):
    r=[]
    for i in l:
        if i%2==0:
            r.append(i)
    return r
def h(s):
    return s.strip().lower().replace(" ","_")
