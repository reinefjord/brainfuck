Processor: Intel i5-5200U (2.2GHz/2.7GHz turbo)

# Python
## bf.py, very naive

### bench.b
```
real    14m8.526s
user    14m8.542s
sys     0m0.010s
```

### mandel.b
```
real    209m11.773s
user    209m11.755s
sys     0m0.374s
```


## bf2.py, non-slot

### bench.b
```
real    10m21.137s
user    10m21.162s
sys     0m0.010s
```

### mandel.b
```
real    103m31.439s
user    103m30.069s
sys     0m0.813s
```


## bf2.py, slotted

### bench.b
```
real    9m10.573s
user    9m10.418s
sys     0m0.127s
```

### mandel.b
```
real    93m11.907s
user    93m10.734s
sys     0m0.673s
```


## pypy3 bf2.py, slotted

### bench.b
```
real    0m29.793s
user    0m29.759s
sys     0m0.033s
```

### mandel.b
```
real    2m36.409s
user    2m36.338s
sys     0m0.063s
```

# Rust
## rustc -C opt-level=3 bf.rs

### bench.b
```
real    0m2.536s
user    0m2.536s
sys     0m0.001s
```

### mandel.b
```
real    0m30.233s
user    0m30.229s
sys     0m0.003s
```
