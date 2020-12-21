mutable struct RouteStop
    f::Int
    Q::Vector{Int}

    RouteStop(; f, Q) = new(f, Q)
end

mutable struct Route
    r::Int
    j::Int
    x::Int
    u::Int

    F::Int
    stops::Vector{RouteStop}

    Route(; r, j, x, u, F, stops) = new(r, j, x, u, F, stops)
end

function Base.show(io::IO, route::Route)
    str = "Route $(route.r)"
    str *= "\n   Jour $(route.j)"
    str *= "\n   Nb de camions $(route.x)"
    str *= "\n   Usine de départ $(route.u)"
    str *= "\n   Nb d'arrêts $(route.F)"
    for (stoprank, stop) in enumerate(route.stops)
        str *= "\n   Stop $stoprank"
        str *= "\n      Fournisseur $(stop.f)"
        str *= "\n      Livraison $(stop.Q)"
    end
    print(io, str)
end

function lire_route(row::String)::Route
    row_split = split(row, r"\s+")
    r = parse(Int, row_split[2]) + 1
    j = parse(Int, row_split[4]) + 1
    x = parse(Int, row_split[6])
    u = parse(Int, row_split[8]) + 1
    F = parse(Int, row_split[10])

    stops = RouteStop[]

    k = 11
    while k <= length(row_split)
        f = parse(Int, row_split[k+1]) + 1
        k += 2

        Q = Int[]
        while (k <= length(row_split)) && (row_split[k] == "e")
            push!(Q, parse(Int, row_split[k+3]))
            k += 4
        end
        push!(stops, RouteStop(f = f, Q = Q))
    end

    return Route(r = r, j = j, x = x, u = u, F = F, stops = stops)
end

function nb_stops(route::Route)::Int
    return route.F
end

function nb_km(route::Route, instance::Instance)::Int
    usines, fournisseurs = instance.usines, instance.fournisseurs
    path = [
        usines[route.u].v
        [fournisseurs[stop.f].v for stop in route.stops]
    ]
    return sum(instance.graphe.d[s, t] for (s, t) in zip(path[1:end-1], path[2:end]))
end

function pickup(route::Route, ; u::Int, e::Int, j::Int)::Int
    if (route.j == j) && (route.u == u)
        return route.x * sum(stop.Q[e] for stop in route.stops)
    else
        return 0
    end
end

function delivery(route::Route; f::Int, e::Int, j::Int)::Int
    if route.j == j
        d = 0
        for stop in route.stops
            if stop.f == f
                d += route.x * stop.Q[e]
            end
        end
        return d
    else
        return 0
    end
end

# function write_road(f, route)
#     write(f, "r $(route.r) j $(route.j) x $(route.x) u $(route.u) F $(route.F) ")
#     for i in 1:route.F
#         write(f, "f $(route.stops[i].f) ")
#         for p in 1:length(route.stops[i].Q)
#             write(f, "e $(p-1) q $(route.stops[i].Q[p]) ")
#         end
#     end
#     write(f, "\n")
# end

# function rewrite(file_name)
#     line = readline(file_name)
#     text = read(file_name, String)
#     open(file_name, "r+") do f
#         new_line = line[1:2] * string(parse(Int, line[3:sizeof(line)])+1)
#         text = replace(text, line=>new_line)
#         print(f, text)
#     end
# end

# function write_sol(file_name, route)
#     if !(isfile(file_name))
#         open(file_name, "w") do f
#             write(f, "R 1\n")
#             write_road(f, route)
#         end
#     else
#         rewrite(file_name)
#         open(file_name, "a") do f
#             write_road(f, route)
#         end
#     end
# end