# How to write maths in this website

This website is built with Franklin.jl and renders maths with KaTeX.

The relevant files are:

- `config.md`: global LaTeX-style commands used across the site
- `_layout/head.html`: loads KaTeX CSS when Franklin detects maths on the page
- `_layout/foot.html`: loads KaTeX JS when Franklin detects maths on the page

In practice, you usually just write maths in a Markdown page and Franklin handles the rest.

## 1. Inline maths

Use single dollar signs:

```md
The energy is $E = mc^2$.
```

Example:

```md
The state space is $\R^3$ and the average is $\scal{x}$.
```

The commands `\R` and `\scal{...}` already exist in `config.md`.

## 2. Display maths

Use double dollar signs for standalone equations:

```md
$$
E_\mathrm{dihed}(\phi) = \sum_{\phi \in \Phi} k_\phi (1 + \cos(n_\phi\phi - \delta_\phi))
$$
```

You can also use `\[ ... \]`:

```md
\[
f'(c) = \frac{f(b)-f(a)}{b-a}
\]
```

Both styles are already used in this repository.

## 3. Equation environments

Environment syntax also works:

```md
\begin{equation}
y = ax
\end{equation}
```

If you want alignment, try:

```md
\begin{align}
f(x) &= x^2 + 2x + 1 \\
f'(x) &= 2x + 2
\end{align}
```

## 4. Labels and references

Equation labels can be placed inside display maths:

```md
$$
\label{eq1_dihed_ene}
E_\mathrm{dihed}(\phi) = \sum_{\phi \in \Phi} k_\phi (1 + \cos(n_\phi\phi - \delta_\phi))
$$
```

Then refer to the equation in text:

```md
As shown in \eqref{eq1_dihed_ene}, the energy depends on the dihedral angle.
```

This pattern is already used in `notebooks/cmap-note.md`.

## 5. Site-wide custom commands

The site already defines these maths commands in `config.md`:

```tex
\newcommand{\R}{\mathbb R}
\newcommand{\scal}[1]{\langle #1 \rangle}
```

So you can use them directly in any page:

```md
Let $x \in \R^n$ and define $\scal{x}$ as its average.
```

If you want more reusable commands, add them to `config.md`.

## 6. Theorem-like blocks already available

This website also defines Franklin commands for styled theorem/admonition blocks:

- `\def{title}{body}`
- `\thm{title}{body}`
- `\lemma{title}{body}`
- `\prop{title}{body}`
- `\proof{body}`
- `\derivation{body}`
- `\results{body}`
- `\requirements{body}`
- `\note{body}`
- `\key{body}`

Example:

```md
\thm{Fundamental Theorem}{
If a function $f$ is continuous on $[a,b]$ and differentiable on $(a,b)$, then there exists $c \in (a,b)$ such that
\[
f'(c) = \frac{f(b)-f(a)}{b-a}.
\]
}
```

See `drafts/test_theorem.md` for working examples.

## 7. A complete example

```md
+++
title = "My maths note"
tags = ["math"]
summary = ""
+++

# My maths note

Let $x \in \R$.

$$
\label{eq:quadratic}
f(x) = x^2 + 2x + 1
$$

From \eqref{eq:quadratic}, we obtain

\[
f'(x) = 2x + 2.
\]

\proof{
Differentiate the polynomial term by term.
}
```

## 8. Local preview

To check that the maths renders correctly:

```julia
using Franklin
serve()
```

Or build the production output:

```bash
julia --project=. build.jl
```

## 9. Practical tips

- Use `$...$` for inline maths.
- Use `$$...$$` or `\[...\]` for display maths.
- Use `\label{...}` and `\eqref{...}` when you need references.
- Put reusable commands in `config.md`, not inside each note.
- If a page contains maths, Franklin should detect it and the layout will load KaTeX automatically.
- Check the rendered page locally if a complex environment does not display as expected.
