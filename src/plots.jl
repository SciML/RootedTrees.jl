
RecipesBase.@recipe function plot(t::RootedTree)
  # Compute x and y coordinates recursively
  width = 2.0
  height = 1.0
  x, y = _plot_coordinates(t, 0.0, 0.0, width, height)

  # Series properties
  seriescolor --> :black
  markershape --> :circle
  markersize  --> 6
  linewidth   --> 2

  # Geometric properties
  grid --> false
  ticks --> false
  foreground_color_border --> :white
  legend --> :bottomright

  # We need to filter out `NaN` since these pollute `extrema`
  x_min, x_max = extrema(Iterators.filter(!isnan, x))
  if x_min ≈ x_max
    xlims --> (x_min - width/2, x_max + width/2)
  end
  y_min, y_max = extrema(Iterators.filter(!isnan, y))
  if y_min ≈ y_max
    ylims --> (y_min - height/2, y_max + height/2)
  end

  # Annotations
  label --> "tree " * string(t.level_sequence)

  x, y
end

function _plot_coordinates(t::AbstractRootedTree,
                           x_root::T, y_root::T,
                           width::T,  height::T) where {T}
  # Indicate a new line series by `NaN`
  nan = convert(T, NaN)
  x = [x_root]
  y = [y_root]

  # Compute plot coordinates recursively
  subtr = subtrees(t)

  # Distribute children uniformly in x and at equal y coordinates
  y_child = y_root + height
  num_children = length(subtr)
  distance = width * (num_children - 1) / 2

  x_children = range(x_root - distance, x_root + distance, length=num_children)
  for idx in eachindex(subtr)
    x_child = x_children[idx]
    push!(x, nan, x_root, x_child)
    push!(y, nan, y_root, y_child)
    x_recursive, y_recursive = _plot_coordinates(subtr[idx],
      x_child, y_child, width / 3, height)
    append!(x, x_recursive)
    append!(y, y_recursive)
  end

  return x, y
end



RecipesBase.@recipe function plot(t::ColoredRootedTree)
  # Compute x and y coordinates recursively
  width = 2.0
  height = 1.0
  # TODO: ColoredRootedTree. Use distinguishable_colors from Colors.jl?
  # color_idx = unique(t.color_sequence)
  # color_val = distinguishable_colors(length(color_idx))
  # colormap = Dict{eltype(color_idx), eltype(color_val)}()
  # for (idx, val) in zip(color_idx, color_val)
  #   colormap[idx] = val
  # end
  x, y = _plot_coordinates(t, 0.0, 0.0, width, height)

  # Series properties
  seriescolor --> :black
  markershape --> :circle
  markersize  --> 6
  linewidth   --> 2

  # Geometric properties
  grid --> false
  ticks --> false
  foreground_color_border --> :white
  legend --> :bottomright

  # We need to filter out `NaN` since these pollute `extrema`
  x_min, x_max = extrema(Iterators.filter(!isnan, x))
  if x_min ≈ x_max
    xlims --> (x_min - width/2, x_max + width/2)
  end
  y_min, y_max = extrema(Iterators.filter(!isnan, y))
  if y_min ≈ y_max
    ylims --> (y_min - height/2, y_max + height/2)
  end

  # Annotations
  label --> "tree " * string((t.level_sequence, t.color_sequence))

  x, y
end
