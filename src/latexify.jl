
"""
    latexify(t::RootedTree)

Return a LaTeX representation of the rooted tree `t`. This makes use of the
LaTeX package [forest](https://ctan.org/pkg/forest) and assumes that you use
the following LaTeX code in the preamble.

```
% Classical and colored Butcher trees based on
% https://tex.stackexchange.com/a/673436
\\usepackage{forest}
\\forestset{
    whitenode/.style={draw,             circle, minimum size=0.5ex, inner sep=0pt},
    blacknode/.style={draw, fill=black, circle, minimum size=0.5ex, inner sep=0pt},
    colornode/.style={draw, fill=#1,    circle, minimum size=0.5ex, inner sep=0pt},
    colornode/.default={red}
}
\\newcommand{\\blankforrootedtree}{\\rule{0pt}{0pt}}
\\NewDocumentCommand\\rootedtree{o}{\\begin{forest}
    for tree={grow'=90, thick, edge=thick, l sep=0.5ex, l=0pt, s sep=0.5ex},
    delay={
      where content={}{
        for children={no edge, before drawing tree={for tree={y-=5pt}}}
      }
      {
        where content={o}{content={\blankforrootedtree}, whitenode}{
          where content={.}{content={\blankforrootedtree}, blacknode}{}
        }
      }
    }
    [#1]
\\end{forest}}

```

# Examples

```jldoctest
julia> rootedtree([1, 2, 2]) |> RootedTrees.latexify |> println
\\rootedtree[.[.][.]]

julia> rootedtree([1, 2, 3, 3, 2]) |> RootedTrees.latexify |> println
\\rootedtree[.[.[.][.]][.]]
```
"""
function latexify(t::RootedTree)
    if isempty(t)
        return "\\varnothing"
    end
    list_representation = butcher_representation(t, false)
    s = "\\rootedtree" * replace(list_representation, "τ" => "[]")
    return replace(s, "[" => "[.")
end

Latexify.@latexrecipe function _(t::RootedTree)
    return Latexify.LaTeXString(RootedTrees.latexify(t))
end
