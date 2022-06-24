
"""
    latexify(t::RootedTree)

Return a LaTeX representation of the rooted tree `t`. This makes use of the
LaTeX package [forest](https://ctan.org/pkg/forest) and assumes that you use
the following LaTeX code in the preamble.

```
% Butcher trees, cf. https://tex.stackexchange.com/questions/283343/butcher-trees-in-tikz
\\usepackage{forest}
\\forestset{
  */.style={
    delay+={append={[]},}
  },
  rooted tree/.style={
    for tree={
      grow'=90,
      parent anchor=center,
      child anchor=center,
      s sep=2.5pt,
      if level=0{
        baseline
      }{},
      delay={
        if content={*}{
          content=,
          append={[]}
        }{}
      }
    },
    before typesetting nodes={
      for tree={
        circle,
        fill,
        minimum width=3pt,
        inner sep=0pt,
        child anchor=center,
      },
    },
    before computing xy={
      for tree={
        l=5pt,
      }
    }
  }
}
\\DeclareDocumentCommand\\rootedtree{o}{\\Forest{rooted tree [#1]}}
```

# Examples

```jldoctest
julia> rootedtree([1, 2, 2]) |> RootedTrees.latexify |> println
\\rootedtree[[][]]

julia> rootedtree([1, 2, 3, 3, 2]) |> RootedTrees.latexify |> println
\\rootedtree[[[][]][]]
```
"""
function latexify(t::RootedTree)
    if isempty(t)
        return "\\varnothing"
    end
    list_representation = butcher_representation(t, false)
    "\\rootedtree" * replace(list_representation, "τ" => "[]")
end

Latexify.@latexrecipe function _(t::RootedTree)
    return Latexify.LaTeXString(RootedTrees.latexify(t))
end
