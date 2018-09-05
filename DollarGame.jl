using LightGraphs, JuMP, Cbc, Plots
gr(size=(600,600))

function dollar_game(g, W)
  nv = length(vertices(g))

  model = Model(solver = CbcSolver())
  @variable(model, give[1:nv] >= 0, Int)
  @variable(model, take[1:nv] >= 0, Int)
  @objective(model, Min, sum(give[i] + take[i] for i = 1:nv))
  @expression(model, x[i=1:nv], W[i] +
              (take[i] - give[i]) * length(neighbors(g, i)) +
              sum(give[j] - take[j] for j = neighbors(g, i)))
  @constraint(model, x .>= 0)
  status = solve(model)

  println("status = $status")
  if status != :Optimal
    return zeros(nv), W
  end

  give = Int.(getvalue(give))
  take = Int.(getvalue(take))
  sol = Int.(getvalue(x))
  return give - take, sol
end

function plot_common!(p, g, W, game=[])
  nv = length(vertices(g))
  θ = 2π / nv
  t = (1:nv) * θ - 1.5θ
  r = 2.5
  x, y = r * sin.(t), r * cos.(t)

  for i = 1:nv
    for j = neighbors(g, i)
      plot!([x[i], x[j]], [y[i], y[j]], lw=2, c=:black)
    end
  end
  scatter!(x, y, ann=[(x[i],y[i],W[i]) for i = 1:nv], m=(30,:white,stroke(2,:black)))
  if length(game) > 0
    annotate!([(1.2x[i], 1.2y[i], game[i], :red) for i = 1:nv])
  end
  xlims!(-1.3r, 1.3r)
  ylims!(-1.3r, 1.3r)
  return p
end

function plot_common(g, W, game=[])
  p = plot(leg=false, axis=false, grid=false)
  return plot_common!(p, g, W, game)
end

function plot_graph(g, W, filename, game=[])
  p = plot_common(g, W, game)
  png(filename)
end

function plot_game(g, W, prefix, game)
  p = plot_common(g, W)
  nv = length(vertices(g))
  k = 0
  fname = @sprintf("%s-%03d", prefix, k)
  title!("Initial")
  png(p, fname)

  θ = 2π / nv
  t = (1:nv) * θ - 1.5θ
  r = 2.5
  x, y = r * sin.(t), r * cos.(t)

  for i = 1:nv
    for n = 1:abs(game[i])
      k += 1
      ng = neighbors(g, i)
      s = sign(game[i])
      W[i] -= s * length(ng)
      c = s > 0 ? RGB(0.1, 0.4, 0.9) : :red

      W[ng] .+= s

      p = plot(leg=false, axis=false, grid=false)
      plot_common!(p, g, W)
      for j = ng
        v = [x[j] - x[i]; y[j] - y[i]]
        σ = 0.4 / norm(v)
        X = [x[i] + v[1] * σ; x[j] - v[1] * σ]
        Y = [y[i] + v[2] * σ; y[j] - v[2] * σ]
        if s < 0
          X, Y = X[[2;1]], Y[[2;1]]
        end
        plot!(X, Y, c=c, lw=3, l=:arrow)
      end
      scatter!([x[i]], [y[i]], m=(30,c,stroke(3,:black)))
      scatter!([x[ng]], [y[ng]], m=(30,c,stroke(3,:black)))
      I = setdiff(1:nv, [i; ng])
      scatter!([x[I]], [y[I]], m=(30,:white,stroke(2,:black)))

      fname = @sprintf("%s-%03d", prefix, k)
      title!("Move $k")
      png(fname)
    end
  end
end

function example()
  g = Graph(5)
  W = [1; -2; 3; 2; -1]
  add_edge!(g, 1, 2)
  add_edge!(g, 1, 3)
  add_edge!(g, 2, 3)
  add_edge!(g, 2, 5)
  add_edge!(g, 3, 4)

  plot_graph(g, W, "example")
  game, sol = dollar_game(g, W)
  plot_graph(g, sol, "example-sol", game)
  plot_game(g, W, "example", game)
end

function example2()
  g = Graph(3)
  W = [0; 1; -1]
  add_edge!(g, 1, 2)
  add_edge!(g, 1, 3)
  add_edge!(g, 2, 3)

  game, sol = dollar_game(g, W)
end

function example3()
  g = Graph(3)
  W = [-2; -1; 4]
  add_edge!(g, 1, 2)
  add_edge!(g, 2, 3)

  game, sol = dollar_game(g, W)
end

example()
example2()
example3()
