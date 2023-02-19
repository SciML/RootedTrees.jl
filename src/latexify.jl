
"""
    latexify(t::Union{RootedTree, BicoloredRootedTree})

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
        where content={o}{content={\\blankforrootedtree}, whitenode}{
          where content={.}{content={\\blankforrootedtree}, blacknode}{}
        }
      }
    }
    [#1]
\\end{forest}}

```

To change the style of `latexify` to a human-readable Butcher-representation,
you can use [`RootedTrees.set_latexify_style`](@ref).

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
    latexify_style = @load_preference("latexify_style", "forest")
    if latexify_style == "butcher"
        return butcher_representation(t)
    else # forest
        list_representation = butcher_representation(t, false)
        s = "\\rootedtree" * replace(list_representation, "τ" => "[]")
        return replace(s, "[" => "[.")
    end
end

function latexify(t::BicoloredRootedTree)
    if isempty(t)
        return "\\varnothing"
    end
    latexify_style = @load_preference("latexify_style", "forest")
    if latexify_style == "butcher"
        return butcher_representation(t)
    else # forest
        list_representation = butcher_representation(rootedtree(t.level_sequence), false)
        s = "\\rootedtree" * replace(list_representation, "τ" => "[]")
        # The first entry of `substrings` is "\\rootedtree".
        substrings = split(s, "[")
        strings = String[]
        for (color, substring) in zip(t.color_sequence, substrings)
            if color == false
                push!(strings, substring * "[.")
            elseif color == true
                push!(strings, substring * "[o")
            end
        end
        # We still need to add the last part dropped by `zip`.
        push!(strings, last(substrings))
        return join(strings)
    end
end

Latexify.@latexrecipe function _(t::Union{RootedTree, BicoloredRootedTree})
    return Latexify.LaTeXString(RootedTrees.latexify(t))
end

"""
    RootedTrees.set_latexify_style(style::String)

Set the style of rooted trees when using [`latexify`](@ref). Possible options are

- "butcher": print the [`butcher_representation`](@ref) of rooted trees
- "forest": use the LaTeX macro `\\rootedtree` described in the docstring of
  [`latexify`](@ref)

This system is based on [Preferences.jl](https://github.com/JuliaPackaging/Preferences.jl).
"""
function set_latexify_style(style::String)
    if !(style in ("butcher", "forest"))
        throw(ArgumentError("Invalid printing style: \"$(style)\""))
    end

    @set_preferences!("latexify_style"=>style)
end
