function reecriture_routes(routes)
    Routes = []
    R = 0
    for route in routes
        R += 1
        new_route = Route(r=R, j=route.j, x=route.x, u=route.u, F=route.F, stops=route.stops)
        push!(Routes, new_route)
    end
    return Routes
end

function descente_locale(routes, instance, nbre_iter)
    U = instance.U
    J = instance.J
    Routes = []
    for j in 1:J
        for u in 1:U
            new_routes = []
            R = []
            for r in 1:length(routes)
                if (routes[r].j == j && routes[r].u == u)
                    push!(new_routes, routes[r])
                    push!(R, r)
                end
            end
            for r in 1:length(R)
                deleteat!(routes, R[length(R) - r + 1])
            end
            if length(new_routes) > 1
                new_routes = descente(new_routes, instance, nbre_iter)
            end
            for route in new_routes
                push!(Routes, route)
            end
        end
    end
    Routes = reecriture_routes(Routes)
    return Routes
end

function descente(new_routes, instance, nbre_iter)
    for i in 1:nbre_iter
        r = rand(1:length(new_routes))
        for road in 1:length(new_routes)
            if (road != r && fusion_possible(new_routes[r], new_routes[road], instance.emballages, instance.L, instance))
                route = fusion(new_routes[r], new_routes[road], instance)
                deleteat!(new_routes, max(r, road))
                deleteat!(new_routes, min(r, road))
                push!(new_routes, route)
                break
            end
        end
    end
    return new_routes
end

function poids_camion(route, emballages)
    return sum(route.stops[n].Q[e]*emballages[e].l for n in 1:length(route.stops), e in 1:length(emballages))
end

function fusion_possible(route1, route2, emballages, L, instance)
    if (poids_camion(route1, emballages)+poids_camion(route2, emballages) <= L && route1.F+route2.F <= 4)
        new_road = Route(r=1, j=route1.j, x=1, u=route1.u, F=route1.F+route2.F, stops = recalcule_stops(route1.u, instance.U, route1.stops, route2.stops, instance.graphe.d))
        if (cost(new_road, instance) < cost(route1, instance) + cost(route2, instance))
            return true
        end
    end
    return false
end

function fusion(route1, route2, instance)
    return Route(r=1, j=route1.j, x=1, u=route1.u, F=route1.F+route2.F, stops = recalcule_stops(route1.u, instance.U, route1.stops, route2.stops, instance.graphe.d))
end

function closest(d, f, F, U)
    min_d = d[f, F[1] + U]
    fourn = F[1]
    for nf in 1:length(F)
        if d[f, F[nf]] < min_d
            min_d = d[f, F[nf]+U]
            fourn = F[nf]
        end
    end
    return fourn
end

function find_stop(stops, f)
    for stop in stops
        if stop.f == f
            return stop
        end
    end
end

function recalcule_stops(u, U, stops1, stops2, d)
    stops = vcat(stops1, stops2)
    new_stops = []
    F = vcat(collect(stops1[i].f for i in 1:length(stops1)),  collect(stops2[i].f for i in 1:length(stops2)))
    f = closest(d, u, F, U)
    F = setdiff(F, f)
    push!(new_stops, find_stop(stops, f))
    i = 0
    while length(F)>0
        f = closest(d, f, F, U)
        F = setdiff(F, f)
        push!(new_stops, find_stop(stops, f))
    end
    return stops
end