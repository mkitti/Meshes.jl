# ------------------------------------------------------------------
# Licensed under the MIT License. See LICENSE in the project root.
# ------------------------------------------------------------------

"""
    DevadossRourke()

Devadoss-Rourke triangulation.

The algorithm is described in the first chapter of Devadoss & Rourke 2011,
and is based on the Polygonal Jordan Curve theorem.

Because the algorithm relies on recursion, it is only appropriate for small
polygonal areas. Currently, the implementation does not support holes.

## References

* Devadoss, S & Rourke, J. 2011. [Discrete and computational geometry]
  (https://press.princeton.edu/books/hardcover/9780691145532/discrete-and-computational-geometry)
"""
struct DevadossRourke end

function discretize(polyarea::PolyArea, ::DevadossRourke)
  # build bridges in case the polygonal area has
  # holes, i.e. reduce to a single outer boundary
  𝒫 = polyarea |> unique |> bridge

  # points on resulting mesh
  points = collect(vertices(𝒫))

  # Devadoss-Rourke recursion
  connec = devadossrourke(points, 1:length(points))

  SimpleMesh(points, connec)
end

function devadossrourke(v::AbstractVector{Point{Dim,T}}, inds) where {Dim,T}
  I = CircularVector(inds)
  n = length(I)

  if n > 3 # split chain
    # find lowest vertex
    i  = 1
    yᵢ = last(coordinates(v[I[1]]))
    for j in 2:n
      yⱼ = last(coordinates(v[I[j]]))
      if yⱼ < yᵢ
        i, yᵢ = j, yⱼ
      end
    end

    # left/right chains
    linds = i-1:i+1
    rinds = i+1:i+n-1

    # check if candidate diagonal is valid
    Δ = Triangle(v[I[linds]])
    intriangle = findall(j -> v[I[j]] ∈ Δ, rinds[2:end-1])
    isdiag = signarea(Δ) > zero(T) && isempty(intriangle)

    # adjust diagonal if necessary
    if !isdiag
      l  = Line(v[I[i-1]], v[I[i+1]])
      js = rinds[intriangle .+ 1]
      k  = argmax([evaluate(Euclidean(), l, v[I[j]]) for j in js])
      j  = js[k]
      linds = i:j
      rinds = j:i+n
    end

    # we adjust the circular indices and
    # use `inds` instead of `I` in the
    # recursion to avoid memory copies
    linds = [mod1(ind,n) for ind in linds]
    rinds = [mod1(ind,n) for ind in rinds]

    # perform recursion
    left  = devadossrourke(v, inds[linds])
    right = devadossrourke(v, inds[rinds])
    [left; right]
  else
    # return the triangle
    [connect(Tuple(inds), Triangle)]
  end
end
