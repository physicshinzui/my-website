+++
title = "Theorem environment"
tags = ["environment"]
summary = ""
+++



# test theorem.
\thm{Fundamental Theorem}{
If a function $f$ is continuous on $[a,b]$ and differentiable on $(a,b)$, then there exists $c \in (a,b)$ such that
\[
f'(c) = \frac{f(b)-f(a)}{b-a}.
\]
}

\lemma{Auxiliary Bound}{
Let $x > 0$. Then
\[
\log(1+x) \le x.
\]
}

\prop{Simple Closure}{
If $A$ and $B$ are finite sets, then $A \cup B$ is also finite.
}

\results{
The numerical experiment converged within 200 steps and the final loss decreased below $10^{-4}$.
}

\requirements{
- Julia 1.11 or later
- Franklin.jl
- A browser with JavaScript enabled
}

\derivation{
Starting from
\[
f(x) = x^2 + 2x + 1,
\]
we obtain
\[
f'(x) = 2x + 2.
\]
}

\proof{
Apply the mean value theorem to $f$ on the interval $[a,b]$. The assumptions guarantee the existence of such a point $c$.
}
