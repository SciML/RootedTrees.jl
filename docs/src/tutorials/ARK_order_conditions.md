# Additive Runge-Kutta methods

Consider an ordinary differential equation (ODE) of the form
```math
u'(t) = f(u(t)).
```

A Runge-Kutta method with ``s`` stages is given by its
Butcher coefficients
```math
A \in \mathbb{R}^{s \times s}, \quad
b \in \mathbb{R}^{s}, \quad
c \in \mathbb{R}^{s},
```
which are often written in form of the Butcher tableau
```math
\begin{array}{c|cc}
  c & A \\
  \hline
  & b^T \\
\end{array}
```
The step from ``u^{n}`` to ``u^{n+1}`` is given by
```math
\begin{aligned}
  y^i &= u^n + \Delta t \sum_\nu \sum_j a^\nu_{i,j} f^\nu(y^i), \\
  u^{n+1} &= u^n + \Delta t \sum_\nu \sum_i b^\nu_{i} f^\nu(y^i),
\end{aligned}
```
where ``y^i`` are the stage values.
