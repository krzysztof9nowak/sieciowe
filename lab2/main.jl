using Graphs
using GraphPlot
using Random
using Statistics    
using Plots                                                                                                                                                                                                                    

function make_graph() :: Graph
    g = path_graph(20)

    add_edge!(g, 1, 3)
    add_edge!(g, 1, 5)
    add_edge!(g, 1, 20)
    add_edge!(g, 5, 15)
    add_edge!(g, 10, 15)
    add_edge!(g, 15, 19)
    add_edge!(g, 5, 8)
    add_edge!(g, 13, 20)
    add_edge!(g, 9, 20)
    add_edge!(g, 2, 12)

    return g
end

function generate_flow(n)
    a = 30 .+ 70 .* rand(n, n)
    for i=1:n
        a[i, i] = 0
    end

    return a
end

spath(to, r, from) = to == from ? to : [spath(r.parents[to], r, from) to]
invert(edge:: Edge) = Edge(edge.dst, edge.src)
function flow_in_edges(graph, flow_matrix)
    n = nv(graph)
    flow_edges :: Dict{Edge, Float64} = merge(
        Dict(e => 0.0 for e in edges(graph)),
        Dict(invert(e) => 0.0 for e in edges(graph))
    )


    for from = 1:n
        r = dijkstra_shortest_paths(graph, from)
        for to=1:n
            if to == from
                continue
            end
            x = flow_matrix[from, to]
            path = spath(to, r, from)
            for (i, j) in zip(path[1:end-1], path[2:end])
                flow_edges[Edge(i, j)] += x
            end
        end
    end

    return flow_edges
end

function average_delay(flow_matrix :: Matrix, flow_edges :: Dict, capacity :: Dict)
    G = sum(flow_matrix)

    T = sum(flow_edges[e]/(capacity[e] - flow_edges[e]) for e in keys(flow_edges))

    T /= G

    return T
end

@enum NetworkFailures NotConnected ExceededCapacity ExceededDelay NoFailure
function verify(g::Graph, m :: Matrix, capacity :: Dict; T_max::Float64 = 1.0) :: NetworkFailures
    if !is_connected(g)
        return NotConnected
    end
    flow = flow_in_edges(g, m)
    for (edge, f) in flow
        if f > capacity[edge]
            return ExceededCapacity
        end
    end
    
    T = average_delay(m, flow, capacity)

    if T > T_max
        return ExceededDelay
    end

    return NoFailure
end

function measure_reliability(g :: Graph, m::Matrix, capcity::Dict, p::Float64, T_max :: Float64; cnt=1000)
    results :: Dict{NetworkFailures, Int} = Dict(NotConnected => 0, ExceededCapacity => 0, ExceededDelay => 0, NoFailure => 0)
    for i=1:cnt
        damaged_g = Graph(g)
        for edge in edges(g)
            if rand() > p
                rem_edge!(damaged_g, edge)
            end
        end
        r = verify(damaged_g, m, capcity, T_max = T_max)
        results[r] += 1
    end

    return results
end


@userplot StackedArea

# a simple "recipe" for Plots.jl to get stacked area plots
# usage: stackedarea(xvector, datamatrix, plotsoptions)
@recipe function f(pc::StackedArea)
    x, y = pc.args

    n = length(x)
    y = cumsum(y, dims=2)
    seriestype := :shape

    # create a filled polygon for each item
    for c=1:size(y,2)
        sx = vcat(x, reverse(x))
        sy = vcat(y[:,c], c==1 ? zeros(n) : reverse(y[:,c-1]))
        @series (sx, sy)
    end
end

function show_reliability(x, points)
    n = sum(values(points[1]))

    no_fail = [a[NoFailure] / n for a in points]
    exceed_cap = [a[ExceededCapacity] / n for a in points]
    exceed_delay = [a[ExceededDelay] / n for a in points]
    no_connection = [a[NotConnected] / n for a in points]
    y = [no_fail exceed_cap exceed_delay no_connection]
    labels = ["OK", "Limit obciążenia", "Limit opóźnienia", "Nie połączone"]
    p = stackedarea(x, y, labels=reshape(labels, (1,4)), legend=:bottomright)
    ylabel!("Prawdopodobieństwo")
    return p
end

function experiment_p()
    g = make_graph()
    m = generate_flow(nv(g))
    flow = flow_in_edges(g, m)

    capacity = Dict(edge => 2 * f  for (edge, f) in flow)

    T = average_delay(m, flow, capacity)


    ps = 0.90 : 0.005 : 1.0
    results = [measure_reliability(g, m, capacity, p, 1.1*T) for p in ps]

    p = show_reliability(ps, results)
    xlabel!("p")
    savefig(p, "experiment_p.png")
    gui(p)
end


function experiment_p2()
    g = make_graph()
    m = generate_flow(nv(g))
    flow = flow_in_edges(g, m)

    capacity = Dict(edge => 2 * f  for (edge, f) in flow)

    T = average_delay(m, flow, capacity)


    ps = 0.0 : 0.05 : 1.0
    results = [measure_reliability(g, m, capacity, p, 1.1*T) for p in ps]

    p = show_reliability(ps, results)
    xlabel!("p")
    savefig(p, "experiment_p2.png")
    gui(p)
end

function experiment_N()
    g = make_graph()
    m = generate_flow(nv(g))
    flow = flow_in_edges(g, m)

    capacity = Dict(edge => 2 * f  for (edge, f) in flow)

    T = average_delay(m, flow, capacity)


    ks = [10^u for u=-1:0.05:1]
    p = 0.975
    results = [measure_reliability(g , m .* k, capacity, p, 1.1*T) for k in ks]

    p = show_reliability(ks, results)
    xaxis!(:log)
    xlabel!("Wzrost intensywności ruchu k")
    savefig(p, "experiment_N.png")
    gui(p)
end


function add_results(x :: Vector{Dict{NetworkFailures, Int}})
    result = Dict()
    for key in [NotConnected ExceededCapacity ExceededDelay NoFailure]
        val = 0
        for sample in x
            val += sample[key]
        end
        result[key] = val
    end

    return result
end

function add_random_edges(g::Graph, k::Int, capacity)
    g = copy(g)
    n = nv(g)
    mean_capacity = mean(values(capacity))
    new_cap = copy(capacity)
    while ne(g) < k
        i = rand(1:n)
        j = rand(1:n)
        
        if i == j
            continue
        end

        e = Edge(i, j)
        if add_edge!(g, e)
            new_cap[e] = mean_capacity
            new_cap[invert(e)] = mean_capacity
        end
    end

    return g, new_cap
end

function experiment_topo()
    g = make_graph()
    m = generate_flow(nv(g))
    flow = flow_in_edges(g, m)

    capacity = Dict(edge => 2 * f  for (edge, f) in flow)

    T = average_delay(m, flow, capacity)


    es = 29:5:100
    p = 0.975
    results = Vector()
    for e in es
        temp_res = Vector{Dict{NetworkFailures, Int}}()
        for i=1:30
            new_g, new_cap = add_random_edges(g, e, capacity)
            r = measure_reliability(new_g , m, new_cap, p, 1.1*T, cnt=100)
            push!(temp_res, r)
        end
        push!(results, add_results(temp_res))
    end

    p = show_reliability(es, results)
    xlabel!("Liczba krawędzi")
    savefig(p, "experiment_topo.png")
    gui(p)
end

function main()
    g = make_graph()
    draw(PNG("network.png", 15cm, 15cm), gplot(g, nodelabel=1:nv(g)))

    m = generate_flow(nv(g))
    flow = flow_in_edges(g, m)

    median_flow = median(collect(values(flow)))
    capacity = Dict(edge => 2 * f + 0.5 * median_flow for (edge, f) in flow)

    T = average_delay(m, flow, capacity)
    @show T

    r = measure_reliability(g, m, capacity, 0.99, 2*T)
    @show r
end

# main()
# experiment_p()
# experiment_p2()
# experiment_N()
experiment_topo()