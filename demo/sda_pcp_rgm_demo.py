#!/usr/bin/env python3
# Tiny toy demo. NOT real crypto; shows the pipeline idea.
import math, hashlib, json

def hazard(lam, tau):
    return 1 - math.exp(-lam * tau)

def clip(x, lo, hi):
    return max(lo, min(hi, x))

def water_filling(a, umax, B, eps=1e-6):
    lo = min(-ai - umax[i] for i, ai in enumerate(a))
    hi = max(-ai for ai in a)
    while hi - lo > eps:
        lam = 0.5 * (lo + hi)
        u = [clip(-ai - lam, 0.0, umax[i]) for i, ai in enumerate(a)]
        if sum(u) > B:
            lo = lam
        else:
            hi = lam
    lam = 0.5 * (lo + hi)
    return [clip(-ai - lam, 0.0, umax[i]) for i, ai in enumerate(a)]

def quantize(x, Delta):
    return [int(round(v/Delta)) for v in x]

def inner(a, x):
    return sum(ai*xi for ai, xi in zip(a, x))

def residues(Arows, xq, primes):
    return [inner(a, xq) % p for a, p in zip(Arows, primes)]

def merkle_root(leaves_bytes):
    layer = [hashlib.sha256(b).digest() for b in leaves_bytes]
    if not layer:
        return b""
    while len(layer) > 1:
        if len(layer) % 2 == 1:
            layer.append(layer[-1])
        nxt = []
        for i in range(0, len(layer), 2):
            nxt.append(hashlib.sha256(layer[i] + layer[i+1]).digest())
        layer = nxt
    return layer[0]

def main():
    mu, omega, delta = 0.012, 0.18, 0.12
    bumps = 0.04
    past_mins = [25, 12, 4]
    tau = 8.0
    L = [3, 5, 7]
    umax = [8, 10, 12]
    B = 24.0
    Delta = 0.01
    Arows = [[2,1,0,3],[1,4,1,2],[3,0,5,1]]
    primes = [101,103,107]
    excit = sum(math.exp(-delta*t) for t in past_mins)
    lam = mu + omega*excit + bumps
    h = hazard(lam, tau)
    a = [-h*Li for Li in L]
    u = water_filling(a, umax, B)
    x = [h] + u
    xq = quantize(x, Delta)
    r = residues(Arows, xq, primes)
    metas = [b"meta1", b"meta2", b"meta3"]
    leaves = [hashlib.sha256(str(ri).encode() + b"||" + mi).digest() for ri, mi in zip(r, metas)]
    root = merkle_root(leaves)
    print(json.dumps({
        "xq": xq,
        "residues": r,
        "primes": primes,
        "merkle_root_hex": root.hex(),
        "policy": "demo-only"
    }, indent=2))
if __name__ == "__main__":
    main()
